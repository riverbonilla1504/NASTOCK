# 17 · Mapa de módulos

Índice para **investigar solo lo necesario**. Al empezar una historia de
usuario no se analiza el proyecto entero (es lento y caro en tokens): se
identifican los módulos afectados y se estudian de punta a punta solo esos.

Las rutas de código son las **planificadas**. Cuando una historia crea,
mueve o renombra algo, actualiza este mapa en el mismo PR.

---

## 1. Protocolo de investigación acotada

```
1. Leer la historia: criterios, reglas (RN/RR/PM), casos borde (CB) y el campo
   "Módulos afectados" (M-xx). Si falta, deducirlo con §3 y agregarlo al issue.
2. Por cada módulo afectado, leer SOLO:
     · las secciones de docs/ que lista (no los documentos completos)
     · las entradas de docs/errores-conocidos.md con ese módulo
     · sus rutas de BD, funciones y app
3. Trazar el flujo de la historia de punta a punta dentro de esos módulos:
     pantalla → provider → repositorio → RPC / Edge Function → tablas y reglas
     → evento en tiempo real → pantalla
4. Mirar las "dependencias" del módulo solo en su interfaz (firma de la RPC,
   columnas de la tabla), no su implementación, salvo que la historia la cambie.
5. Si aparece la necesidad de tocar un módulo no listado: agregarlo al issue y
   repetir 2–4 solo para ese módulo.
6. Al terminar: actualizar este mapa si cambiaron rutas, tablas o funciones.
```

---

## 2. Módulos

### M-01 · Identidad y acceso
- **Qué hace**: ingreso con Google, invitaciones, hooks de Auth, sesión, bloqueo biométrico.
- **Docs**: 04 completo · 03 §6 · 12 §1
- **BD**: `invitaciones`, `parametros` (`auth.*`); `private.antes_de_crear_usuario`, `private.al_crear_usuario`, `private.token_personalizado` (migración `supabase/migrations/*_token_personalizado.sql`; se registra en `supabase/config.toml`, sección `[auth.hook.custom_access_token]`); RPC `invitar_usuario`, `revocar_invitacion`
- **Funciones**: `admin-usuarios`
- **App**: `lib/features/auth/`, `lib/app/enrutador.dart` (enrutador y guardas; hoy solo la ruta `/inicio`)
- **Pruebas**: `supabase/tests/auth_*.sql`, `supabase/tests/database/03_perfiles_roles_y_token_test.sql` (claims del token) · E2E-01, E2E-02
- **Depende de**: M-02 · **Lo usan**: todos

### M-02 · Perfiles, roles y permisos
- **Qué hace**: rol y estado de cada persona, funciones de autorización, RLS base, cambio de rol, suspensión, baja y reincorporación.
- **Docs**: 03 completo · 08 §5 · 02 §11
- **BD**: `perfiles` y los tipos `rol_app` y `estado_cuenta` (migraciones `supabase/migrations/*_perfiles_tipos_y_tabla.sql` y `*_perfiles_politica_de_lectura.sql`; `perfiles.invitacion_id` sin llave foránea hasta HU-002); `private.rol_actual`, `private.es_supervisor` (`*_rol_actual_y_es_supervisor.sql`); RPC `cambiar_rol`; `private.suspender_cuenta`, `reactivar_cuenta`, `dar_de_baja`, `reincorporar`
- **Funciones**: `admin-usuarios`
- **App**: `lib/features/admin/usuarios/`, `lib/core/perfil/` (`perfil.dart`, `perfil_repositorio.dart`, `perfil_provider.dart`: claims del token y fila de `perfiles`, `perfilProvider`)
- **Pruebas**: `supabase/tests/database/02_perfiles_rls_test.sql`, `supabase/tests/database/03_perfiles_roles_y_token_test.sql`, `test/core/perfil/` (y las de roles de las historias siguientes, con el mismo prefijo `NN_` de `supabase/tests/database/`) · E2E-05, E2E-16
- **Depende de**: M-01, M-17 · **Lo usan**: todos

### M-03 · Libro contable
- **Qué hace**: subcuentas, movimientos de doble partida, invariantes del libro.
- **Docs**: 02 §2 · 06 §4
- **BD**: `fondos`, `subcuentas`, `movimientos`, `asientos`; `private.registrar_movimiento`
- **Funciones**: —
- **App**: — (lo consumen M-15 y M-16)
- **Pruebas**: `supabase/tests/libro_*.sql`
- **Depende de**: — · **Lo usan**: M-04, M-10, M-11, M-12, M-15

### M-04 · Capital, cupos, reparto y rebalanceo
- **Qué hace**: aportes, retiros, cupos, reparto 50/25/25 de aportes y ganancias, rebalanceo.
- **Docs**: 02 §3–§5, §7, §8, §14 · 08 §4 · 12 §2
- **BD**: `movimientos_capital`; RPC `registrar_aporte`, `anular_aporte`, `registrar_retiro`, `asignar_cupo`, `reducir_cupo`, `solicitar_liquidacion`; `private.crear_cupo`, `private.proponer_rebalanceo`, reparto dentro de `private.aplicar_llenado`
- **Funciones**: `conciliacion` (confirma aportes), `cierre-diario` (rebalanceo)
- **App**: `lib/features/admin/capital/`, `lib/features/admin/cupos/`
- **Pruebas**: `supabase/tests/capital_*.sql`, `reparto_*.sql` · E2E-04, E2E-08
- **Depende de**: M-02, M-03, M-12 · **Lo usan**: M-15

### M-05 · Datos de mercado
- **Qué hace**: universo NASDAQ-100 y ETFs, precios cada 15 s, barras, calendario y reloj, atributos de activos, estado del mercado, pantalla de mercado.
- **Docs**: 09 §1–§2 · 10 §11–§12 · 02 §12 · 06 §5.2
- **BD**: `lista_blanca`, `cotizaciones`, `barras_minuto`, `barras_diarias`, `calendario_mercado`, tipo `bolsillo`; RPC `estado_mercado`; `private.publicar_cotizaciones`, `private.mercado_abierto`, `mercado_en_ventana`, `ventana_compras_abierta`, `private.simbolos_del_universo`, `simbolos_sin_historia`, `guardar_barras_diarias`, `private.margenes_de_compra` (5 y 15 minutos de docs/02 §10 hasta que exista `parametros`), `private.sincronizar_calendario`, `sincronizar_activos`; trabajo `calendario` de `pg_cron` (diario, 10:00 UTC) · migraciones `supabase/migrations/*_lista_blanca_y_barras.sql` (tipo, tres tablas y semilla del universo), `*_funciones_de_mercado.sql`, `*_lectura_del_mercado.sql` (políticas de lectura), `*_calendario_mercado.sql` (tabla y lectura), `*_funciones_de_horario.sql` (horario y sincronización), `*_trabajo_calendario.sql` y `*_estado_mercado.sql` (márgenes, ventana de compras y la RPC) · un año de barras de prueba en `supabase/seed.sql`
- **Funciones**: `ingesta-mercado`, `calendario-mercado` (`index.ts`, `manejador.ts`, `carga_historica.ts`: carga inicial de dos años de barras diarias, `sincronizacion.ts`: calendario, reloj y atributos de los activos), `cierre-diario`; `_shared/mercado/` (`interfaz.ts`, `alpaca.ts`, `simulado.ts`, `mod.ts` con `crearProveedorDeMercado`, `tiempo.ts`, `fixtures/` con respuestas de Alpaca); `_shared/broker/` (`interfaz.ts` con `calendario`, `reloj` y `activos`, `alpaca.ts`, `simulado.ts` con reloj de mercado configurable por `RELOJ_SIMULADO`, `mod.ts` con `crearBroker`, `fixtures/`; solo `calendario-mercado` lo importa)
- **App**: `lib/features/mercado/`
- **Pruebas**: `supabase/tests/database/04_universo_y_barras_test.sql`, `supabase/tests/database/05_calendario_y_horario_test.sql`, `supabase/functions/_shared/mercado/*_test.ts`, `supabase/functions/_shared/broker/*_test.ts`, `supabase/functions/calendario-mercado/*_test.ts`, `supabase/functions/ingesta-mercado/*_test.ts` · E2E-03
- **Depende de**: M-02, M-19 · **Lo usan**: M-07, M-08, M-11

### M-06 · Noticias y contexto (DeepSeek)
- **Qué hace**: descarga noticias, pide el contexto a DeepSeek, lo valida contra sus fuentes y controla su vigencia.
- **Docs**: 07 §4.2, §13 · 10 §11 · 12 §10
- **BD**: `noticias`, `contextos_ia`, `prompts_agente`; `private.guardar_noticias`, `contexto_vigente`, `encolar_contexto`, `guardar_contexto`; cola `contexto_por_generar`
- **Funciones**: `contexto-ia`; `_shared/noticias/`, `_shared/ia/` (contexto)
- **App**: detalle de contexto dentro de `lib/features/oportunidades/`
- **Pruebas**: `supabase/functions/contexto-ia/*_test.ts` · E2E-06
- **Depende de**: M-05, M-19 · **Lo usan**: M-07

### M-07 · Motor de decisión (IA principal + JEV)
- **Qué hace**: ciclo del agente, calidad de datos, métricas y etiquetas, preguntas a JEV, puntaje compuesto, reglas de decisión, señales, alertas de la IA, oportunidades, opinión sobre órdenes manuales, análisis bajo demanda, evaluación y calibración, configuración versionada y modo sombra.
- **Docs**: 07 completo · 02 §10 (`ia.*`, `jev.*`) · 12 §7, §10
- **BD**: `ciclos_agente`, `evaluaciones_candidatos`, `configuraciones_decision`, `senales`, `propuestas_descartadas`, `opiniones_ia`, `evaluaciones_ia`, `alertas`; RPC `oportunidades`, `desempeno_ia`, `crear_configuracion`, `poner_en_sombra`, `activar_configuracion`; `private.registrar_ciclo`, `registrar_evaluacion`, `crear_senal`
- **Funciones**: `agente`, `opinion-ia`, `cierre-diario` (evaluación); `_shared/ia/` (jev), `_shared/indicadores.ts`, `_shared/decision.ts`
- **App**: `lib/features/oportunidades/`, `lib/features/ia/`, opinión en `lib/features/ordenes/`
- **Pruebas**: `supabase/functions/agente/*_test.ts`, `decision_test.ts` · E2E-06, E2E-07, E2E-11
- **Depende de**: M-05, M-06, M-08, M-19 · **Lo usan**: M-09

### M-08 · Motor de políticas y parámetros
- **Qué hace**: reglas de riesgo RR-01 a RR-22, parámetros con historial, interruptores.
- **Docs**: 02 §9–§10 · 08 §6 (interruptores)
- **BD**: `parametros`, `parametros_historial`, `fondos` (interruptores); `private.validar_operacion`; RPC `actualizar_parametro`, `activar_freno`, `reanudar`
- **Funciones**: — (lo llaman `agente`, `opinion-ia`, `ejecutor-ordenes` y las RPC)
- **App**: `lib/features/admin/parametros/`, freno en la barra
- **Pruebas**: `supabase/tests/politicas_*.sql`
- **Depende de**: M-03, M-05, M-18 · **Lo usan**: M-07, M-09, M-10, M-11

### M-09 · Sugerencias y decisiones
- **Qué hace**: reparto de señales en sugerencias, bandejas, aprobar y rechazar, doble aprobación, vencimiento, invalidación, rebalanceo y liquidación como sugerencias.
- **Docs**: 08 §1, §7–§8 · 07 §7 · 03 PM-11, PM-21, PM-24, PM-43 · 12 §3
- **BD**: `sugerencias`, `decisiones`; RPC `aprobar_sugerencia`, `rechazar_sugerencia`, `bandeja_riesgo`; `private.crear_sugerencias_desde_senal`, `private.vencer_sugerencias`
- **Funciones**: — (las crea `agente`)
- **App**: `lib/features/sugerencias/`, `lib/features/riesgo/`
- **Pruebas**: `supabase/tests/sugerencias_*.sql` · E2E-08, E2E-09, E2E-10
- **Depende de**: M-02, M-03, M-07, M-08 · **Lo usan**: M-10, M-14

### M-10 · Ejecución y órdenes
- **Qué hace**: órdenes (aprobadas, manuales, de protección, de liquidación), cola, envío al broker, sincronización y aplicación de llenados.
- **Docs**: 10 §3, §5, §7, §10 · 08 §2 · 12 §4
- **BD**: `ordenes`, `ordenes_eventos`; RPC `crear_orden_manual`, `cancelar_orden`; `private.tomar_orden_para_envio`, `registrar_respuesta_envio`, `registrar_error_envio`, `aplicar_llenado`; cola `ordenes_por_enviar`
- **Funciones**: `ejecutor-ordenes`, `sincronizar-ordenes`; `_shared/broker/`
- **App**: `lib/features/ordenes/`
- **Pruebas**: `supabase/functions/ejecutor-ordenes/*_test.ts`, `supabase/tests/llenados_*.sql` · E2E-08, E2E-11
- **Depende de**: M-03, M-04, M-08, M-19 · **Lo usan**: M-11, M-12, M-15

### M-11 · Posiciones y protecciones
- **Qué hace**: posiciones con costo promedio, protecciones nativas y virtuales, disparo, ajuste, renovación.
- **Docs**: 08 §3 · 10 §6 · 02 §6–§7 · 12 §5
- **BD**: `posiciones`, `protecciones`, vista `posiciones_valoradas`; RPC `ajustar_proteccion`; `private.disparar_proteccion_virtual`
- **Funciones**: `sincronizar-ordenes` (patas nativas), `ingesta-mercado` (virtuales), `cierre-diario` (renovación)
- **App**: `lib/features/cupo/`
- **Pruebas**: `supabase/tests/protecciones_*.sql` · E2E-08, E2E-12
- **Depende de**: M-05, M-10 · **Lo usan**: M-15

### M-12 · Conciliación
- **Qué hace**: compara broker y libro, confirma aportes, pausa el trading ante descuadres.
- **Docs**: 10 §8 · 08 §6 · 12 CB-40
- **BD**: `conciliaciones`; `private.registrar_conciliacion`; RPC `marcar_conciliacion_revisada`, `lanzar_conciliacion`
- **Funciones**: `conciliacion`
- **App**: `lib/features/admin/salud/`
- **Pruebas**: `supabase/functions/conciliacion/*_test.ts` · E2E-13
- **Depende de**: M-03, M-10, M-19 · **Lo usan**: M-04, M-08

### M-13 · Tiempo real
- **Qué hace**: canales privados, eventos desde la base de datos, gestor de conexión en la app, patrón foto + eventos.
- **Docs**: 09 §3–§4, §7 · 08 §9
- **BD**: política `canales_permitidos` sobre `realtime.messages`; `private.publicar_evento`, `private.carga_evento`; triggers por entidad
- **Funciones**: —
- **App**: `lib/core/realtime/`
- **Pruebas**: `supabase/tests/database/08_realtime_canales_test.sql` · E2E-03, E2E-08
- **Depende de**: M-02 · **Lo usan**: todas las pantallas en vivo

### M-14 · Notificaciones y push
- **Qué hace**: bandeja de notificaciones, dispositivos, envío por FCM, preferencias, deep links.
- **Docs**: 09 §5 · 06 §5.5
- **BD**: `notificaciones`, `dispositivos`; RPC `registrar_dispositivo`, `eliminar_dispositivo`, `marcar_notificaciones_leidas`; cola `notificaciones_push`
- **Funciones**: `notificador`; `_shared/push/`
- **App**: `lib/features/alertas/`, `lib/core/push/`
- **Pruebas**: `supabase/functions/notificador/*_test.ts` · E2E-15
- **Depende de**: M-02, M-13, M-19 · **Lo usan**: M-07, M-09, M-10, M-11, M-12

### M-15 · Cartera, fondo y reportes
- **Qué hace**: mi cupo, resumen y detalle del fondo, fotos diarias, rendimiento TWR, historial, exportación CSV, línea ×2 teórico.
- **Docs**: 02 §13 · 03 §3
- **BD**: `patrimonio_diario`; RPC `mi_cupo`, `resumen_fondo`; `private.tomar_foto_patrimonio`
- **Funciones**: `cierre-diario`
- **App**: `lib/features/cupo/`, `lib/features/fondo/`, `lib/features/reportes/`
- **Pruebas**: pruebas de exportación y del motor ×2 (copiadas de la v2) · E2E-04
- **Depende de**: M-03, M-04, M-11 · **Lo usan**: —

### M-16 · Administración
- **Qué hace**: pantallas del administrador: usuarios, capital, cupos, rebalanceos, parámetros, lista blanca, interruptores, prompts y configuraciones, salud, bitácora.
- **Docs**: 03 §2–§3
- **BD**: RPC de administración de los demás módulos
- **Funciones**: `admin-usuarios`
- **App**: `lib/features/admin/`
- **Pruebas**: widget tests de administración · E2E-01
- **Depende de**: M-02, M-04, M-07, M-08, M-17, M-18 · **Lo usan**: —

### M-17 · Auditoría
- **Qué hace**: bitácora inmutable con cadena de hash, verificación, pantalla y exportación.
- **Docs**: 11 §4
- **BD**: `auditoria` con su política `auditoria_lectura` (solo el Administrador; ningún rol de la API escribe, tampoco `service_role`) · `private.hash_auditoria` (la fórmula del hash, que reutiliza la verificación de la cadena), `private.auditar` (único camino de escritura: toma el bloqueo y encadena el hash; el rol del actor lo lee de `perfiles`) · trigger `auditoria_inmutable` con `private.rechazar_cambio_auditoria` (rechaza `UPDATE`, `DELETE` y `TRUNCATE`) · migraciones `supabase/migrations/*_auditoria_tabla.sql`, `*_auditar.sql` y `*_auditoria_inmutable.sql`
- **Funciones**: `cierre-diario` (ancla en el reporte diario)
- **App**: `lib/features/admin/bitacora/`
- **Pruebas**: `supabase/tests/database/05_auditoria_tabla_y_lectura_test.sql`, `06_auditoria_auditar_test.sql` (encadenado y concurrencia con una segunda conexión de `dblink`), `07_auditoria_inmutable_test.sql` · E2E-14
- **Depende de**: M-02 (`private.rol_actual`, tipo `rol_app`), M-19 (`private.ahora`) · **Lo usan**: casi todos

### M-18 · Salud, alertas e integraciones
- **Qué hace**: estado de cada integración, alertas operativas, presupuesto de IA.
- **Docs**: 06 §5.6 · 08 §6 · 05 §13
- **BD**: `salud_integraciones`, `alertas`; `private.registrar_salud`
- **Funciones**: `_shared/salud.ts` (todas las funciones lo usan)
- **App**: `lib/features/admin/salud/`, `lib/features/alertas/`
- **Pruebas**: `supabase/tests/salud_*.sql`
- **Depende de**: — · **Lo usan**: M-05 a M-14

### M-19 · Proveedores simulados y reloj
- **Qué hace**: implementaciones simuladas de mercado, broker, noticias, DeepSeek, JEV y FCM; reloj controlable; esquema `pruebas`.
- **Docs**: 10 §9 · 15 §3
- **BD**: `private.ahora()` (migración `supabase/migrations/*_reloj_ahora.sql`; busca `pruebas.reloj` al llamarla y sin el esquema devuelve `now()`); esquema `pruebas`, que crea solo `supabase/seed.sql` (ninguna migración): `pruebas.reloj` con `pruebas.fijar_reloj(hora)`, `pruebas.escenarios` con `pruebas.elegir_escenario(proveedor, escenario)` y `pruebas.push_simulados`
- **Funciones**: `_shared/proveedores.ts` (`elegirProveedor`, `leerConfiguracion`; rechaza simulados con `ENTORNO=mvp`), `_shared/*/simulado.ts` (cada uno lo crea la historia de su integración; el de mercado, `_shared/mercado/simulado.ts`, es de HU-026 y su algoritmo se repite en SQL en el bloque de barras de prueba de `supabase/seed.sql`), `supabase/functions/.env.e2e` (`ENTORNO=ci` y `PROVEEDOR_*=simulado`, sin secretos)
- **App**: modo pruebas (ingreso con correo en CI)
- **Pruebas**: `supabase/tests/database/01_reloj_y_pruebas_test.sql`, `supabase/functions/_shared/proveedores_test.ts`, búsqueda en `scripts/verificar.sh` (ninguna migración crea `pruebas`), `supabase/tests/e2e/utilidades/pruebas.ts` (`fijarReloj`, `elegirEscenario`, `restablecer` por conexión directa, porque `pruebas` está cerrado a la API) y `00_arnes_test.ts`; todo el E2E depende de este módulo
- **Depende de**: — · **Lo usan**: M-05, M-06, M-07, M-10, M-12, M-14

### M-20 · Plataforma, CI/CD y calidad
- **Qué hace**: flujos de GitHub Actions, scripts de verificación, despliegue, respaldo, wiki, plantillas, backlog y especificación por historia con spec-kit (D-56).
- **Docs**: 15 completo · 16 completo · 05 §10–§12
- **Planeación y specs**: `backlog/`, `specs/`, `.specify/`, `.claude/skills/`, `scripts/github/` (etiquetas, hitos, proyecto y publicación del backlog como issues)
- **Diseño visual** (D-67, HU-116): `DESIGN.md` (manda en lo visual), `PRODUCT.md` (contexto de producto para impeccable, derivado de 01 a 04), `.impeccable/` (`design.json`, `surfaces/` con el contrato de dirección; `mocks/` y `review/` son locales y no se versionan), `assets/fonts/archivo/` (Archivo, OFL, con `LEEME.md` del origen)
- **BD**: `supabase/config.toml`, `supabase/seed.sql`, esquema `private`, extensiones `pg_cron`, `pg_net` y `pgmq`, `public.ping()`, `latido` (06 §5.6), `private.despertar_funcion(nombre)` · migraciones `supabase/migrations/*_esquema_private_y_extensiones.sql`, `*_latido_y_ping.sql`, `*_despertar_funcion.sql`
- **Funciones**: `supabase/functions/deno.json` (dependencias de todas las funciones, con `postgres` fijado en versión exacta), `_shared/auth.ts` (secreto interno, JWT y rol), `_shared/esquemas.ts` (validación con zod), `_shared/bd.ts` (D-66: única puerta a Postgres; solo funciones `private`, por conexión directa con `SUPABASE_DB_URL`; el único archivo que importa el cliente de Postgres, vigilado por la búsqueda de `scripts/verificar.sh` y de CI) · `[functions.<nombre>]` en `supabase/config.toml` para las funciones que solo aceptan el secreto interno (`verify_jwt = false`)
- **App**: esqueleto Flutter `com.ritech.inversiones` (Android y web): `pubspec.yaml`, `analysis_options.yaml`, `android/`, `web/`, `lib/main.dart`; `lib/app/` (`arranque.dart`, `aplicacion.dart` con tema claro y oscuro, `enrutador.dart`, `tema.dart` con los tokens `ColoresAlmanaque`, `ProfundidadAlmanaque`, `Espacio`, `Radios`, `Duracion` y `Familias`, `pagina_inicio.dart`); `lib/app/catalogo/` (catálogo de componentes en `/catalogo`, registrado solo en debug o con `MODO_PRUEBAS`); `lib/core/configuracion/entorno.dart` (`--dart-define`), `lib/core/supabase/cliente_supabase.dart`, `lib/core/errores/` (`codigos_de_error.dart`, `traduccion_de_errores.dart`), `lib/core/formato/` (`formato_dinero.dart`, `formato_fechas.dart`, `formato_porcentaje.dart`); `lib/shared/widgets/` (componentes del sistema: `botones`, `tarjeta`, `campo`, `avisos` con el aviso temporal, `estados`, `mensaje_de_error`, `cifras`, `chip_de_estado`, `forma_de_linea`, `grafica_de_linea`, `tarjeta_de_cotizacion`, `calendario` con el selector de periodo, `hoja_inferior`, `franja_de_la_jornada`, `barra_superior`, `barra_de_pestanas`); `lib/features/` (vacía hasta la primera historia); `integration_test/app_test.dart` y `test_driver/integration_test.dart` (E2E de la app con `flutter drive -d web-server`, TT-06)
- **Despliegue (TT-08)**: `.github/workflows/despliegue.yml` (jobs `supabase`, `web`, `android` y `humo`; sin variables de proyecto no despliega y avisa), `firebase.json` (Hosting sirve `build/web`), firma de Android en `android/app/build.gradle.kts` (lee `android/key.properties`, que el flujo crea desde los secretos `ANDROID_*` y no se versiona; sin él, `--release` firma con la llave de debug)
- **Pruebas**: `scripts/verificar.sh` (en el E2E de backend arma `supabase/.temp/env.e2e` = `.env.e2e` + el `SECRETO_INTERNO` de prueba de `seed.sql`, que las funciones necesitan y `.env.e2e` no lleva), `scripts/verificar_docs.py`, `supabase/tests/deno.json` (dependencias de `e2e/` y `humo/`; se usa con `--config`), `supabase/tests/e2e/` (`utilidades/`: `entorno.ts`, `sesion.ts`, `funciones.ts`, `pruebas.ts`; `00_arnes_test.ts`: escenario mínimo; cada historia agrega el suyo de docs/15 §4), `supabase/tests/humo/` (prueba de humo de 15 §11; corre contra la nube con `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY`: `entorno.ts`; `salud_test.ts`: `ping()`; `proveedores_y_auth_test.ts`: las funciones arrancan sin simulados en `mvp` (CB-91) y el correo está deshabilitado en Auth (CB-92); TT-06/TT-08), `integration_test/`, `test_driver/`, `supabase/tests/database/00_base_test.sql`, `supabase/functions/_shared/*_test.ts` (incluye `bd_test.ts`), `test/` (espejo de `lib/`: errores, formato, entorno, app con el tema y el catálogo, una prueba por componente en `test/shared/widgets/`)
- **Depende de**: — · **Lo usan**: todos

---

## 3. De palabras de la historia a módulos

| Si la historia habla de… | Módulos |
|---|---|
| ingresar, invitación, Google, sesión, biometría | M-01, M-02 |
| rol, suspender, baja, permisos, "no puede ver" | M-02 |
| aporte, retiro, capital, cupo, reparto, rebalanceo | M-04, M-03 |
| precio, mercado abierto, NASDAQ, gráfica, universo | M-05 |
| noticias, contexto, DeepSeek | M-06 |
| IA, JEV, oportunidad, puntaje, confianza, opinión, calibración | M-07 |
| límite, regla de riesgo, parámetro, freno, pausar | M-08 |
| sugerencia, aprobar, rechazar, vencer, doble aprobación | M-09 |
| orden, ejecutar, broker, llenado, cancelar | M-10 |
| posición, stop-loss, take-profit, protección | M-11 |
| descuadre, conciliación | M-12 |
| en vivo, actualización automática | M-13 |
| notificación, push, aviso | M-14 |
| mi cupo, fondo, rendimiento, reporte, exportar | M-15 |
| pantalla de administración | M-16 + el módulo del tema |
| bitácora, auditoría | M-17 |
| salud, integración caída, alerta operativa | M-18 |
| simulado, demo, prueba E2E, reloj | M-19 |
| CI, despliegue, wiki, respaldo | M-20 |
| tema, colores, tipografía, componente visual, catálogo, `DESIGN.md` | M-20 |
