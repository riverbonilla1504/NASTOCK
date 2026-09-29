# 11 · Seguridad y auditoría

## 1. Qué protegemos

| Activo | Por qué importa | Peor caso |
|---|---|---|
| **Capacidad de enviar órdenes** | Mueve el dinero del fondo | Órdenes no autorizadas |
| **Integridad del libro contable** | Define de quién es cada peso | Saldos alterados, repartos falsos |
| **Llaves** (Alpaca, DeepSeek, TypeSafe/Cloudflare, FCM, Supabase) | Dan acceso directo a los servicios | Operación fuera de la plataforma, costos |
| **Cuentas de los empleados** | Cada una decide sobre dinero | Suplantación |
| **Datos personales** (nombre, correo) | Obligación legal (Ley 1581) | Filtración |
| **Protecciones de las posiciones** | Limitan pérdidas | Pérdidas sin tope si fallan |

---

## 2. Amenazas y controles

| Amenaza | Ejemplo | Controles |
|---|---|---|
| Suplantación de identidad | Alguien usa la cuenta de otro empleado | Google Workspace con verificación en dos pasos exigida; app interna de Google; solo invitados; biometría para decidir; JWT de 15 min |
| Escalada de privilegios | Un Usuario intenta aprobar Arriesgadas o ver otros cupos | RLS en todas las tablas; escrituras solo por RPC que validan rol y dueño; rol leído de la tabla, no del token; pruebas pgTAP |
| Cliente modificado | App alterada que llama la API directo | Mismo resultado: la seguridad está en la base de datos, no en la app |
| Manipulación del libro | Editar un saldo | Sin permisos de escritura; asientos inmutables (trigger); suma cero verificada; recálculo diario |
| Repudio | "Yo no aprobé eso" | Decisión con usuario, hora, precio al decidir y confirmación biométrica; bitácora encadenada con hash |
| Órdenes duplicadas | Reintento envía dos veces | `client_order_id` = id de la orden; consulta antes de reintentar |
| IA manipulada o equivocada | Una noticia con texto malicioso intenta influir en DeepSeek o JEV; un modelo se equivoca | Noticias resumidas y verificadas contra sus fuentes; JEV solo recibe etiquetas y afirmaciones respaldadas; respuestas tipadas; motor de políticas; aprobación humana; ningún modelo tiene herramientas de ejecución (07 §12) |
| Fuga de datos a la IA | Datos personales en lo enviado a DeepSeek o JEV | Estado y contexto con campos cerrados; prueba automática que busca correos, nombres y uuid de personas |
| Filtración de llaves | Llave de Alpaca en el repositorio | Solo en secretos de Supabase; escaneo de secretos en CI; rotación; ver §5 |
| Denegación de servicio / caída de terceros | Alpaca, DeepSeek o JEV caídos | Salud con estados; RR-21; protecciones nativas en el broker; P7 "ante la duda, no operar" |
| Operación fuera de la plataforma | Alguien opera desde el panel de Alpaca | Prohibido; la conciliación lo detecta y pausa el trading |
| Abuso interno del admin | El admin intenta aprobar una compra | Imposible por diseño (D-20); todo lo que sí puede hacer queda auditado |
| Acceso al panel de Supabase | Un desarrollador con acceso total | Mínimos miembros en la organización de Supabase, MFA obligatorio en sus cuentas, cambios solo por migraciones revisadas |

---

## 3. Controles por capa

| Capa | Controles |
|---|---|
| **Identidad** | Google Workspace (interna), invitación obligatoria, hook de alta, bloqueo en Auth al suspender, JWT de 15 min, refresh tokens rotativos |
| **Autorización** | RLS en todas las tablas de `public`; `anon` sin acceso; funciones `security definer` con `search_path = ''`; esquema `private` no expuesto; Realtime con canales privados y políticas |
| **Datos** | Restricciones `CHECK` y `UNIQUE` para invariantes de dinero; libro inmutable; `numeric` para dinero; conciliación con el broker |
| **Integraciones** | Llaves solo en Edge Functions; secreto interno para las llamadas del cron; validación de todo lo externo; idempotencia; tiempos de espera |
| **IA** | Sin llaves ni herramientas; esquema estricto; motor de políticas; presupuesto; contexto sin datos personales |
| **App** | Sesión en almacenamiento seguro; bloqueo biométrico; sin montos en push; sin secretos en el binario; errores genéricos en pantalla |
| **Operación** | Interruptores y freno de emergencia; alertas; migraciones revisadas en PR; nadie opera en el panel del broker |

---

## 4. Bitácora de auditoría

### 4.1 Qué se registra

| Categoría | Acciones (`auditoria.accion`) |
|---|---|
| Cuentas | `cuenta.invitada`, `cuenta.invitacion_revocada`, `cuenta.activada`, `cuenta.rol_cambiado`, `cuenta.suspendida`, `cuenta.reactivada`, `cuenta.baja` |
| Capital | `capital.aporte_registrado`, `capital.aporte_confirmado`, `capital.aporte_anulado`, `capital.retiro_registrado`, `capital.retiro_confirmado` |
| Cupos | `cupo.asignado`, `cupo.reducido`, `cupo.cerrado`, `cupo.liquidacion_solicitada` |
| Decisiones | `sugerencia.aprobada`, `sugerencia.rechazada`, `decision.anulada`, `rebalanceo.aprobado`, `rebalanceo.rechazado` |
| Operación | `orden.manual_creada`, `orden.cancelada`, `proteccion.ajustada`, `proteccion.disparada`, `ajuste.registrado` |
| Configuración | `parametro.cambiado`, `lista_blanca.cambiada`, `interruptor.apagado`, `interruptor.encendido`, `prompt.creado`, `prompt.activado` |
| Control | `conciliacion.descuadre`, `conciliacion.revisada`, `integracion.caida`, `integracion.recuperada`, `ia.presupuesto_agotado` |

No se duplica en la bitácora lo que ya es un registro inmutable propio
(cada sugerencia, orden, ciclo del agente y asiento contable tiene su
historia en su tabla).

**Nunca** se registran llaves, tokens ni el contenido de las respuestas de
Google.

### 4.2 Inicios de sesión y accesos denegados

- Los **inicios de sesión** los registra Supabase Auth en su propio registro
  de auditoría; no se duplican.
- Los **accesos denegados** (`NO_AUTORIZADO`) no se pueden escribir en
  `auditoria` desde la misma función, porque el error revierte la
  transacción completa. Quedan en los registros de la API de Supabase
  (código de error, usuario, función) y se revisan con el explorador de
  registros. Un resumen diario de denegaciones por usuario llega al admin.

### 4.3 Inmutable y verificable

1. Ningún rol de la API puede escribir en `auditoria`; solo
   `private.auditar()`.
2. Un trigger rechaza cualquier `UPDATE` o `DELETE`, incluso de la llave
   secreta.
3. **Cadena de hash**: cada registro guarda
   `hash = sha256(hash_anterior ‖ momento ‖ actor ‖ acción ‖ entidad ‖ id ‖ detalle)`.
   `auditar()` toma un bloqueo para que dos inserciones simultáneas no usen
   el mismo `hash_anterior`.
4. Un trabajo semanal recalcula la cadena; si se rompe, alerta crítica.
5. El reporte diario al admin incluye el último hash del día (ancla fuera de
   la base de datos): alterar el pasado obligaría a alterar también esos
   reportes.

### 4.4 Quién la ve

Solo el Administrador (PM-60), con filtros por persona, acción, entidad y
rango de fechas, y exportación CSV.

---

## 5. Secretos

| Secreto | Dónde vive | Quién lo usa | Rotación |
|---|---|---|---|
| Llaves de Alpaca (por entorno) | Secretos de Edge Functions | ingesta, ejecutor, sincronización, conciliación, calendario | Trimestral y ante cualquier sospecha |
| Llave de DeepSeek | Secretos de Edge Functions | contexto-ia | Trimestral |
| Llave de TypeSafe (o token de Cloudflare Workers AI) | Secretos de Edge Functions | agente, opinion-ia | Trimestral |
| Clave de cifrado de respaldos | Secreto de GitHub Actions | flujo de mantenimiento | Anual (guardar copia fuera de GitHub) |
| Cuenta de servicio de Firebase | Secretos de Edge Functions | notificador | Anual |
| Llave secreta de Supabase | Automática en Edge Functions | Todas las funciones | Ante sospecha |
| Secreto interno (cron → funciones) | Vault + secretos de Edge Functions | `pg_net` y todas las funciones internas | Semestral |
| Secreto del cliente OAuth de Google | Configuración de Auth en Supabase | Supabase Auth | Ante sospecha |

**Si se filtra una llave**: (1) freno de emergencia (`trading_activo`
apagado), (2) revocar la llave en el proveedor y crear otra, (3) actualizar
el secreto, (4) conciliar y revisar órdenes y actividad del periodo en el
broker, (5) reanudar, (6) registrar el incidente.

En CI se ejecuta un escáner de secretos en cada PR.

---

## 6. Privacidad y datos personales

Marco: **Ley 1581 de 2012** (protección de datos personales en Colombia) y
sus decretos reglamentarios.

| Principio | Cómo se cumple |
|---|---|
| Datos mínimos | Solo nombre y correo corporativo (vienen de Google). La v2 pedía documento y celular: **se eliminan** porque no se necesitan. |
| Finalidad | Identificar a quién decide sobre el dinero del fondo y avisarle. Se declara en un aviso de privacidad interno que se acepta al primer ingreso. |
| Transferencia internacional | Supabase, Google y Firebase guardan datos fuera de Colombia: se declara en la política de tratamiento de RiTech. A **DeepSeek y a JEV no se envían datos personales** (07 §4.5), así se evita una transferencia adicional. TypeSafe declara que no entrena con los datos de sus clientes. |
| Acceso y rectificación | Cada persona ve su perfil; el nombre se corrige en Google Workspace. |
| Seguridad | Todo este documento. |
| Conservación | El historial de operaciones se conserva por su valor contable aunque la persona se retire; su cuenta queda bloqueada, no borrada (RN-40). |

**Región de Supabase**: elegir la más cercana con buena latencia hacia
Colombia y hacia los servicios de Alpaca en EE. UU. (p. ej. Este de EE. UU.).
Decisión en Q-10.

---

## 7. Respaldo y recuperación

| Tema | Plan |
|---|---|
| Respaldos | El plan gratuito de Supabase **no incluye respaldos**. El flujo diario de GitHub Actions hace `supabase db dump` (esquema y datos), lo **cifra con GPG** (AES-256, clave en un secreto de GitHub) y lo guarda como artefacto 7 días. Cifrado porque, si el repositorio es público, los artefactos pueden ser visibles. |
| Objetivo de pérdida de datos (RPO) | ≤ 24 h. |
| Objetivo de recuperación (RTO) | ≤ 4 h. |
| Fuente de verdad externa | Si se perdiera información reciente, el broker tiene las órdenes y posiciones reales: la conciliación y la consulta por `client_order_id` permiten reconstruir lo operado. |
| Simulacro | Descifrar y restaurar un respaldo en local una vez al mes y conciliar. |

---

## 8. Respuesta a incidentes

```
1. CONTENER   Freno de emergencia: apagar ia_activa y/o trading_activo (analista o admin).
              Las protecciones siguen funcionando.
2. EVALUAR    Salud de integraciones, última conciliación, bitácora, ciclos de IA, órdenes recientes.
3. CORREGIR   Nunca editando: movimientos de ajuste justificados, anulaciones, cambios de parámetros.
4. REANUDAR   Solo el admin, tras una conciliación en 'ok'.
5. REGISTRAR  Qué pasó, impacto, causa y qué se cambió para que no se repita.
```

| Incidente | Primera acción |
|---|---|
| Descuadre crítico | El sistema ya pausó el trading. Revisar la diferencia símbolo por símbolo. |
| La IA propone cosas raras de forma repetida | Apagar `ia_activa`; revisar el último prompt activado y los ciclos. |
| Cuenta de empleado comprometida | Suspender (bloquea en Auth y corta RLS al instante); revisar sus decisiones. |
| Llave filtrada | §5. |
| Broker caído con posiciones fraccionales abiertas | Avisar a los dueños; las protecciones virtuales no funcionan sin datos. |

---

## 9. Pruebas de seguridad

| Prueba | Cuándo |
|---|---|
| pgTAP: por cada tabla, un Usuario no ve filas ajenas y ningún rol escribe directo | Cada PR |
| pgTAP: cada RPC rechaza al rol equivocado y al dueño equivocado | Cada PR |
| pgTAP: invariantes del libro (suma cero, no negativos, inmutabilidad) | Cada PR |
| Asesor de seguridad de Supabase (linter de la base de datos) sin advertencias | Cada PR |
| La función `agente` no importa el cliente del broker | Cada PR |
| El contexto de la IA no contiene correos ni nombres | Cada PR |
| Escáner de secretos y de dependencias | Cada PR |

---

## 10. Lista de verificación antes de abrir el MVP al equipo

- [ ] Pantalla de consentimiento de Google en modo **Interna**.
- [ ] Verificación en dos pasos exigida en Google Workspace.
- [ ] MFA en todas las cuentas con acceso al panel de Supabase, Alpaca, Google Cloud y Firebase.
- [ ] RLS activo en todas las tablas (asesor de Supabase en verde).
- [ ] JWT a 15 minutos.
- [ ] Secretos cargados por entorno; ninguno en el repositorio.
- [ ] Primer administrador creado por invitación de despliegue, sin credenciales de prueba.
- [ ] Paquete `com.ritech.inversiones` y huellas SHA-1 de release registradas en Google.
- [ ] Interruptores apagados hasta el primer aporte confirmado.
- [ ] Conciliación en `ok`.
- [ ] Aviso de privacidad y aviso de "no es asesoría financiera" aprobados.
- [ ] Simulacro de restauración hecho (descifrar un respaldo y restaurarlo en local).
- [ ] Proveedores reales en el proyecto MVP; correo + contraseña deshabilitado en la nube (CB-91, CB-92).
