# 12 · Casos borde

Catálogo de situaciones anómalas y la respuesta esperada. Cada caso es
candidato directo a **criterio de aceptación** o a **prueba automática**.
Cuando la respuesta ya está definida en otro documento, se cita.

---

## 1. Identidad y acceso

| ID | Situación | Qué hace el sistema | Ref. |
|---|---|---|---|
| CB-01 | Un empleado del dominio **sin invitación** intenta entrar | El hook de alta rechaza; no se crea el usuario; mensaje "Tu correo no tiene una invitación vigente…" | 04 §5 |
| CB-02 | La invitación **venció** (7 días) | Igual que CB-01. El admin crea una invitación nueva. | 04 §5 |
| CB-03 | El admin invita un correo que **ya tiene cuenta** | `CORREO_YA_REGISTRADO`. Si la cuenta está de baja, se ofrece reincorporar (CB-06). | 06 §9 |
| CB-04 | El admin invita **dos veces** el mismo correo | `INVITACION_DUPLICADA`. Puede revocar la vigente y crear otra. | 06 §5.1 |
| CB-05 | Workspace **cambia el correo** de un empleado | La identidad está ligada al identificador de Google, no al correo. En el siguiente ingreso Supabase actualiza `auth.users` y un trigger sincroniza `perfiles.email` y lo audita. | RN-58 |
| CB-06 | Un empleado dado de baja **vuelve a la empresa** | El admin usa "Reincorporar": la cuenta vuelve a `activo` con un **cupo nuevo en 0**; el cupo viejo sigue cerrado con su historial. | 08 §5 |
| CB-07 | Se suspende a alguien **con la app abierta** | RLS le corta los datos al instante; evento `sesion_revocada` cierra su sesión; su cupo queda congelado. | 04 §10 |
| CB-08 | Un empleado **pierde el teléfono** | Biometría y bloqueo protegen la app. El admin suspende la cuenta (o el admin de Workspace cierra sus sesiones de Google) y la reactiva cuando tenga otro dispositivo. | 04 §8 |
| CB-09 | Intento de suspender, dar de baja o cambiar de rol al **último admin**, o de aplicarse la acción **a sí mismo** | `ULTIMO_ADMIN` / `AUTO_ACCION`. | RN-50, RN-51 |
| CB-10 | Cambio de rol con cosas vivas: Usuario con posiciones pasa a Analista; analista con una 1ª aprobación pendiente pasa a otro rol | `CUPO_CON_POSICIONES` (primero se liquida); la 1ª aprobación se anula y la sugerencia vuelve a `pendiente`. | RN-54, RN-56 |

## 2. Dinero y cupos

| ID | Situación | Qué hace el sistema | Ref. |
|---|---|---|---|
| CB-11 | Aporte registrado pero el broker **no tiene** el dinero | Queda `registrado`; la conciliación no lo confirma; alerta al admin a la hora. El admin espera o lo anula. | RN-07 |
| CB-12 | Aporte que no se divide exacto en centavos (1.000,03) | Arriesgadas y Usuarios truncados; la Reserva recibe el resto. | RN-09 |
| CB-13 | Retiro mayor al disponible de la Reserva | `FONDOS_INSUFICIENTES`. El admin elige otra subcuenta o rebalancea primero. | RN-14 |
| CB-14 | Asignar un cupo mayor a lo que hay en la bolsa común | `FONDOS_INSUFICIENTES`. | RN-16 |
| CB-15 | Invitación con cupo inicial que la bolsa común no cubre | El empleado entra igual con cupo 0; alerta `cupo_inicial_no_asignado` al admin. | RN-18 |
| CB-16 | Reducir el cupo de alguien que tiene casi todo invertido | Solo se puede reducir hasta su disponible. | RN-17 |
| CB-17 | El admin cambia los porcentajes de reparto con ventas en curso | Cada reparto usa los porcentajes vigentes **al llenarse la venta** y los guarda en el movimiento. | RN-08, RN-26 |
| CB-18 | Ganancia de centavos (0,03) | Arriesgadas 0,00 · cupo 0,00 · Reserva 0,03 (truncamiento). | RN-30 |
| CB-19 | Un cupo pierde 100 y luego gana 100 | Se reparte la ganancia de 100 igual: el cupo termina con menos que al inicio. Es consecuencia del reparto por operación (pendiente de validar). | RN-29, Q-01 |
| CB-20 | *(Retirado: aplicaba a dinero real, fuera del alcance.)* | — | — |

## 3. Sugerencias y decisiones

| ID | Situación | Qué hace el sistema | Ref. |
|---|---|---|---|
| CB-21 | Se aprueba en el **mismo segundo** del vencimiento | Decide `now()` de la base de datos dentro de la transacción. Si ya venció: `VENCIDA`. | 08 §8 |
| CB-22 | El precio sale de la banda **mientras la persona está mirando** | La sugerencia pasa a `invalidada` con el motivo; la pantalla lo muestra. Si alcanza a pulsar Aprobar: `FUERA_DE_BANDA`. | RR-12 |
| CB-23 | Dos analistas aprueban **a la vez** | Bloqueo de fila: uno queda como 1ª, el otro como 2ª aprobación. | 08 §8 |
| CB-24 | El mismo analista intenta dar las **dos** aprobaciones | `MISMO_ANALISTA`; su primera decisión no cambia. | RN-52 |
| CB-25 | Solo hay **un analista activo** y la compra supera el umbral | La IA recorta el monto justo por debajo del umbral. Si el segundo analista se suspende después de una 1ª aprobación, la sugerencia sigue esperando y vence si nadie más la decide. | RR-13 |
| CB-26 | Un analista aprueba y otro **rechaza** | `rechazada`: un rechazo basta. | 08 §1 |
| CB-27 | El dueño del cupo está **de vacaciones** | Puede pausar la recepción de sugerencias. Si no lo hizo, vencen solas. Sus protecciones siguen activas. | PM-15 |
| CB-28 | Llega una sugerencia de compra de un símbolo en el que el usuario ya tiene una **orden manual viva** | No se crea para ese cupo. | RR-10 |
| CB-29 | Se aprueban dos compras y el disponible **alcanza para una** | La segunda aprobación falla con `FONDOS_INSUFICIENTES`; la sugerencia sigue `pendiente` hasta vencer (la persona puede liberar dinero cancelando otra orden). | RN-23 |
| CB-30 | Sugerencia de **venta** de una posición que ya se vendió por protección | `invalidada` ("La posición ya no existe"). | 08 §1 |
| CB-31 | Un usuario **rechaza todo** siempre | No afecta a nada. Queda en las métricas de desempeño y en la memoria de la IA (por código de motivo). | 07 §11 |
| CB-32 | Se apaga `trading_activo` con sugerencias aprobadas pero aún no enviadas | El ejecutor revalida → `fallida` (`TRADING_PAUSADO`) y libera la retención. Las `pendiente` pasan a `invalidada`, salvo las de liquidación. | RR-14 |

## 4. Órdenes y ejecución

| ID | Situación | Qué hace el sistema | Ref. |
|---|---|---|---|
| CB-33 | Se envía la orden y **no llega respuesta** | `desconocida` → consulta por `client_order_id` → si existe, sigue; si no, `error_envio` y se puede reintentar sin riesgo de duplicado. | 08 §2 |
| CB-34 | **Llenado parcial** y luego vence o se cancela | Sugerencia `ejecutada_parcial`; libro y posición por lo llenado; retención restante liberada; protección sobre lo llenado (virtual si era bracket). | 10 §6, Q-12 |
| CB-35 | La compra límite **no se llena** porque el precio se escapó | Se cancela al cumplir el tiempo máximo → `fallida`; retención liberada; aviso. | 10 §5 |
| CB-36 | El broker rechaza por **fondos insuficientes** | No debería pasar (retenemos antes): `fallida` + alerta de posible descuadre. | 10 §10 |
| CB-37 | El usuario **cancela** su orden manual justo cuando se llena | La cancelación falla porque ya se llenó; se trata como llenada y se informa. | 08 §2 |
| CB-38 | Cierra el mercado con una orden `day` viva | `vencida`; lo llenado se conserva. | 08 §2 |
| CB-39 | El activo entra en **halt** con una orden viva | No se llena; se cancela por tiempo máximo; alerta. | 10 §10 |
| CB-40 | Aparece en el broker una orden o un llenado que la plataforma **no conoce** | `descuadre_critico`, trading pausado, alerta: alguien operó por fuera. | 10 §8 |

## 5. Posiciones, protecciones y eventos corporativos

| ID | Situación | Qué hace el sistema | Ref. |
|---|---|---|---|
| CB-41 | ***Split* o agrupación** de acciones de un símbolo con posiciones | La conciliación detecta cantidad distinta → descuadre → el admin registra un **ajuste de evento corporativo**: cantidad × factor, costo promedio ÷ factor, costo total igual. Las protecciones se cancelan y se recrean con precios ajustados. | RN-32 |
| CB-42 | *(Retirado: dividendos, que paper trading no simula.)* | — | — |
| CB-43 | El mercado **abre por debajo del stop** | El stop se ejecuta al precio disponible, peor que el stop. Se informa la diferencia. | 10 §6 |
| CB-44 | Protección **virtual** con datos de precio desactualizados | No puede dispararse. Si pasan más de 5 min en horario de mercado: alerta crítica a los dueños y analistas ("tu protección no está siendo vigilada"). | RSG-05 |
| CB-45 | El usuario ajusta un stop **por encima** del precio actual | Rechazado: el stop debe quedar por debajo del precio actual y dentro de RR-08. | RR-08 |
| CB-46 | Toca el stop una posición de un usuario **suspendido** | Se vende igual; el dinero vuelve a su cupo. | 02 §11 |
| CB-47 | Un símbolo **sale de la lista blanca** con posiciones abiertas | No se compra más; las posiciones y protecciones siguen; la IA puede sugerir vender. | RR-01 |
| CB-48 | Una venta parcial dejaría un **residuo** menor a la orden mínima | Se vende todo. | 07 §7.4 |

## 6. Mercado y datos

| ID | Situación | Qué hace el sistema | Ref. |
|---|---|---|---|
| CB-49 | **Feriado** en EE. UU. | Calendario: cerrado todo el día; sin ingesta ni ciclos. | RN-41 |
| CB-50 | **Media jornada** (cierre 13:00 NY) | Ventana de compras y vencimientos se calculan con el cierre real del calendario. | RN-41 |
| CB-51 | Cambio de horario de verano en EE. UU. | Sin efecto: el calendario está en UTC; la app muestra la hora de Bogotá correcta. | RN-42 |
| CB-52 | **Suspensión general** del mercado (*circuit breaker*) | Precios se congelan → "dato desactualizado" → aprobaciones y compras bloqueadas; órdenes vivas vencen por tiempo. | RR-11 |
| CB-53 | Precio inválido del proveedor (0, negativo, vacío) | Se descarta ese dato y se registra. | 09 §2 |
| CB-54 | Diferencia entre el precio IEX y el consolidado | Aceptada en paper; la banda y la orden límite la absorben. | 09 §2 |
| CB-55 | QQQ se mueve bruscamente (≥ umbral de evento) | Ciclo extra del agente. Si la caída del día supera 3 %, alerta crítica del sistema a todos. | 07 §2 |
| CB-56 | Sugerencias de ayer al abrir hoy | No existen: todas vencieron al cierre. | 07 §7.5 |

## 7. Agente de IA

| ID | Situación | Qué hace el sistema | Ref. |
|---|---|---|---|
| CB-57 | **JEV caído** o sin acceso por horas | Sin sugerencias nuevas; siguen órdenes manuales (sin opinión), ventas, protecciones y alertas del sistema. (Si el caído es **DeepSeek**, el sistema sigue decidiendo "sin contexto".) | 07 §10 |
| CB-58 | DeepSeek devuelve respuesta **vacía** o **JSON inválido** | Un reintento; si falla, se conserva el contexto anterior si está vigente o la candidata queda "sin contexto". | 07 §10 |
| CB-59 | DeepSeek cita **noticias que no se le entregaron** | Se eliminan esas afirmaciones; si son más de la mitad, contexto `no_confiable`. | 07 §4.2 |
| CB-60 | La misma candidata sale elegida **en cada ciclo** | No se crea otra señal mientras haya una viva (RR-10). | 07 §6.3 |
| CB-61 | Se agota el **presupuesto** mensual | Ciclos `omitido`; alerta al admin. | 07 §9 |
| CB-62 | Un ciclo **se cuelga** | El siguiente lo marca `fallido` y sigue. | 07 §3 |
| CB-63 | El admin activa un **prompt o configuración defectuosos** | Freno de IA; activar la versión anterior (las versiones no se borran). | 07 §11 |

## 8. Integraciones y sistema

| ID | Situación | Qué hace el sistema | Ref. |
|---|---|---|---|
| CB-64 | **Alpaca caído** | Salud `caido`; sin órdenes nuevas; protecciones nativas siguen en el broker; las virtuales no pueden ejecutarse (alerta). | RR-21 |
| CB-65 | **FCM** falla | Las notificaciones siguen en la app; el push se reintenta 3 veces. | 09 §5.4 |
| CB-66 | **Realtime** se desconecta | La app reconecta y pide fotos; el push cubre lo urgente. | 09 §7 |
| CB-67 | Una Edge Function supera su **tiempo máximo** | La cola reintenta el trabajo; los ciclos colgados se marcan fallidos. | 05 §8 |
| CB-68 | Un mensaje de la cola falla **5 veces** | Se archiva; la orden queda `error_envio`; alerta al admin. | 05 §8 |
| CB-69 | El **cron deja de correr** (proyecto pausado, error de plataforma) | La app muestra "dato desactualizado" por la antigüedad del precio. Se recomienda un monitor externo de disponibilidad que consulte un endpoint de salud y avise por correo. | RSG-07 |
| CB-70 | El **reloj del teléfono** está desfasado | Las cuentas regresivas usan el desfase medido contra el servidor; las decisiones las valida el servidor. | 08 §9.1 |
| CB-71 | Una **migración falla** a medias | Las migraciones son transaccionales y se prueban completas en CI (base de datos local desde cero) antes de aplicarse al proyecto MVP. | 05 §10 |
| CB-72 | Se **restaura un respaldo** anterior a órdenes que sí ocurrieron en el broker | Trading pausado; la conciliación y la consulta por `client_order_id` reconstruyen lo faltante con ajustes justificados; reanuda con conciliación en `ok`. | 11 §7 |

## 9. Configuración

| ID | Situación | Qué hace el sistema | Ref. |
|---|---|---|---|
| CB-73 | Se cambia la banda o el vencimiento con sugerencias vivas | Las vivas conservan sus parámetros congelados. | RN-39 |
| CB-74 | Se baja el umbral de doble aprobación con sugerencias pendientes | Las vivas conservan su `requiere_doble` original. | RN-39 |
| CB-75 | Se cambia el 50/25/25 | Solo afecta aportes y repartos futuros y la meta del rebalanceo. | RN-02 |
| CB-76 | Se quita un símbolo de la lista blanca con sugerencias vivas | Pasan a `invalidada`. | 08 §1 |
| CB-77 | El admin intenta **reanudar** el trading con un descuadre abierto | Rechazado: reanudar exige la última conciliación en `ok` o el descuadre marcado como revisado. | 11 §8 |
| CB-78 | Porcentajes de reparto que **no suman 100** | `PARAMETRO_FUERA_DE_RANGO`: los tres se cambian juntos en una sola operación. | RN-02 |
| CB-79 | Se configura un **modelo de DeepSeek o una versión de JEV** retirados o inexistentes | Solo se aceptan modelos de la lista permitida; si la API igual lo rechaza, ciclos fallidos y alerta. | 07 §5 |
| CB-80 | **Fondo sin capital** (antes del primer aporte) | Interruptores apagados; la app muestra "Fondo sin capital" y el admin ve la guía de primeros pasos. | RN-11 |

## 10. Contexto, JEV y calidad de datos

| ID | Situación | Qué hace el sistema | Ref. |
|---|---|---|---|
| CB-81 | Alpaca News responde **403** con la cuenta gratuita | Salud `alpaca_noticias` degradada; candidatas "sin contexto"; alerta al admin; se evalúa la alternativa de Q-19. | 10 §11 |
| CB-82 | El contexto de una candidata es **más viejo** que `ia.contexto_max_minutos` o llegaron noticias nuevas | Se evalúa "sin contexto" en este ciclo y se encola la regeneración; nunca se mezcla contexto viejo con precios nuevos sin marcarlo. | 07 §4.2 |
| CB-83 | Una candidata **sin noticias** en 72 h | Contexto `sin_noticias`; las preguntas de contexto quedan neutras; la explicación lo dice. | 07 §6.2 |
| CB-84 | **Los números dicen una cosa y las noticias otra** en una candidata fuerte | No se propone; alerta a analistas con la contradicción explicada. Si la contradicción es parcial y se propone, la sugerencia lleva advertencia. | 07 §6.3 |
| CB-85 | JEV responde con **confianza baja** para todas las candidatas | No se propone nada. Queda registrado como ciclo completado sin señales. | 07 §6.3 |
| CB-86 | **Empate** de puntaje entre dos candidatas | Gana la de mayor confianza de JEV; si persiste, la de menor volatilidad. | 07 §6.3 |
| CB-87 | Una acción del universo tiene **datos incompletos** o un salto anómalo | Se excluye del ciclo con el motivo; si es QQQ, el ciclo se omite. | 07 §4.1 |
| CB-88 | **Reconstitución** anual del NASDAQ-100 (entran y salen empresas) | El admin actualiza la lista; los símbolos que salen se tratan como CB-47. | 10 §12 |
| CB-89 | TypeSafe cambia `jev-latest` | No afecta: la versión está fijada (`ia.modelo_jev`); pasar a otra versión es un cambio de configuración probado en sombra. | 07 §5 |
| CB-90 | El acceso a JEV (acceso anticipado) **aún no se concede** | Se usa el mismo modelo por Cloudflare Workers AI (`JEV_PROVEEDOR=cloudflare`); mientras tanto el desarrollo usa el JEV simulado. | 07 §5 |

## 11. Entornos y pruebas

| ID | Situación | Qué hace el sistema | Ref. |
|---|---|---|---|
| CB-91 | Un proveedor simulado queda configurado en el **proyecto MVP** | La función de arranque se niega a iniciar con `ENTORNO=mvp` y proveedor simulado; la prueba de humo del despliegue falla. | 10 §9 |
| CB-92 | El proveedor de **correo** queda habilitado en la nube | El hook lo rechaza (`auth.proveedores_permitidos` = `["google"]`) y la prueba de humo lo detecta. | 04 §5 |
| CB-93 | El proyecto gratuito de Supabase **se pausa** por inactividad | Lo evitan `pg_cron` y el `ping()` diario; si ocurre, el flujo diario falla y avisa; se reactiva desde el panel. | 05 §3.4 |
| CB-94 | Una prueba E2E **falla de forma intermitente** | No se desactiva ni se reintenta a ciegas: se investiga, se corrige y se registra en `errores-conocidos.md`. | 15 §8 |
