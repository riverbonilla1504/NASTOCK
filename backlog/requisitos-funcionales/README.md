# Requisitos funcionales

Catálogo de los **227 requisitos funcionales** del MVP. Cada archivo de esta carpeta es un requisito y se llama con su identificador y su nombre corto (`FR-001-inicio-de-sesion-con-google.md`). Dentro lleva:

- **Rol o actor**: quién interactúa con el sistema en esa función. Puede ser una persona (Usuario, Analista o Administrador) o un actor no humano de `docs/01` §3 (IA principal, DeepSeek, JEV, broker, datos de mercado, Google Workspace o Firebase).
- **Descripción**: lo que el sistema debe hacer, con un verbo de acción y un resultado que se puede comprobar.
- **Fuente**: la regla, el permiso, el caso borde o la sección de `docs/` de donde sale. Los números remiten a los documentos de [`docs/`](../../docs/README.md): `04 §5` es la sección 5 de `docs/04-autenticacion-oauth.md`.
- **Historias que lo implementan**: las historias o tareas técnicas del backlog que lo cubren.

Ningún requisito agrega comportamiento nuevo: todos reescriben, como requisito verificable, algo que `docs/` ya decide. Los requisitos no funcionales (rendimiento, disponibilidad, costos) no están en este catálogo.

Están agrupados por la épica a la que pertenecen. El identificador no se reutiliza: si un requisito deja de aplicar, se marca como retirado y su número no vuelve a usarse.

## E-01 · Cimientos y calidad continua

| ID | Nombre | Rol o actor | Lo implementan |
|---|---|---|---|
| [FR-001](FR-001-aplicacion-en-android-y-web.md) | Aplicación en Android y web | Usuario, Analista y Administrador | [TT-08](../E-01-cimientos-y-calidad-continua/TT-08-despliegue-continuo-al-proyecto-mvp-con-prueba-de-humo.md) |
| [FR-002](FR-002-mensajes-de-error-en-espanol-por-codigo.md) | Mensajes de error en español por código | Usuario, Analista y Administrador | [TT-04](../E-01-cimientos-y-calidad-continua/TT-04-esqueleto-de-la-app-flutter-para-android-y-web.md) |
| [FR-003](FR-003-formato-de-dinero-y-de-horas.md) | Formato de dinero y de horas | Usuario, Analista y Administrador | [TT-04](../E-01-cimientos-y-calidad-continua/TT-04-esqueleto-de-la-app-flutter-para-android-y-web.md) |
| [FR-004](FR-004-proveedores-simulados-por-integracion.md) | Proveedores simulados por integración | Sistema | [TT-05](../E-01-cimientos-y-calidad-continua/TT-05-base-de-proveedores-simulados-reloj-controlable-y-datos-de-prueba.md) |
| [FR-005](FR-005-rechazo-de-proveedores-simulados-en-el-proyecto-mvp.md) | Rechazo de proveedores simulados en el proyecto MVP | Sistema | [TT-05](../E-01-cimientos-y-calidad-continua/TT-05-base-de-proveedores-simulados-reloj-controlable-y-datos-de-prueba.md) |
| [FR-006](FR-006-reloj-controlable-solo-en-local-y-ci.md) | Reloj controlable solo en local y CI | Sistema | [TT-05](../E-01-cimientos-y-calidad-continua/TT-05-base-de-proveedores-simulados-reloj-controlable-y-datos-de-prueba.md) |
| [FR-007](FR-007-usuarios-de-prueba-solo-en-local-y-ci.md) | Usuarios de prueba solo en local y CI | Sistema | [HU-002](../E-02-identidad-y-acceso/HU-002-alta-solo-con-invitacion-vigente.md) |
| [FR-008](FR-008-latido-del-proyecto.md) | Latido del proyecto | Flujo de mantenimiento (GitHub Actions) | [TT-03](../E-01-cimientos-y-calidad-continua/TT-03-base-de-supabase-esquema-private-extensiones-vault-y-ping.md), [TT-09](../E-01-cimientos-y-calidad-continua/TT-09-mantenimiento-ping-diario-respaldo-cifrado-y-prueba-real-semanal.md) |
| [FR-009](FR-009-prueba-de-humo-tras-cada-despliegue.md) | Prueba de humo tras cada despliegue | Flujo de despliegue (GitHub Actions) | [TT-08](../E-01-cimientos-y-calidad-continua/TT-08-despliegue-continuo-al-proyecto-mvp-con-prueba-de-humo.md), [HU-114](../E-12-seguridad-auditoria-y-cumplimiento/HU-114-lista-de-verificacion-antes-de-abrir-el-mvp-al-equipo.md) |
| [FR-010](FR-010-respaldo-diario-cifrado.md) | Respaldo diario cifrado | Flujo de mantenimiento (GitHub Actions) | [TT-09](../E-01-cimientos-y-calidad-continua/TT-09-mantenimiento-ping-diario-respaldo-cifrado-y-prueba-real-semanal.md), [HU-113](../E-12-seguridad-auditoria-y-cumplimiento/HU-113-simulacro-de-restauracion-de-un-respaldo.md) |
| [FR-011](FR-011-prueba-real-semanal-de-proveedores.md) | Prueba real semanal de proveedores | Flujo de mantenimiento (GitHub Actions) | [TT-09](../E-01-cimientos-y-calidad-continua/TT-09-mantenimiento-ping-diario-respaldo-cifrado-y-prueba-real-semanal.md) |

## E-02 · Identidad y acceso

| ID | Nombre | Rol o actor | Lo implementan |
|---|---|---|---|
| [FR-012](FR-012-inicio-de-sesion-con-google.md) | Inicio de sesión con Google | Usuario, Analista y Administrador | [HU-005](../E-02-identidad-y-acceso/HU-005-ingresar-con-google-en-android-y-web.md) |
| [FR-013](FR-013-alta-solo-con-invitacion-vigente.md) | Alta solo con invitación vigente | Google Workspace y Sistema (hook de alta) | [HU-002](../E-02-identidad-y-acceso/HU-002-alta-solo-con-invitacion-vigente.md) |
| [FR-014](FR-014-perfil-activo-al-aceptar-la-invitacion.md) | Perfil activo al aceptar la invitación | Sistema | [HU-002](../E-02-identidad-y-acceso/HU-002-alta-solo-con-invitacion-vigente.md) |
| [FR-015](FR-015-invitacion-de-una-persona.md) | Invitación de una persona | Administrador | [HU-003](../E-02-identidad-y-acceso/HU-003-invitar-a-una-persona-y-revocar-invitaciones.md) |
| [FR-016](FR-016-revocacion-y-vencimiento-de-invitaciones.md) | Revocación y vencimiento de invitaciones | Administrador | [HU-003](../E-02-identidad-y-acceso/HU-003-invitar-a-una-persona-y-revocar-invitaciones.md) |
| [FR-017](FR-017-primer-administrador-por-configuracion-de-despliegue.md) | Primer administrador por configuración de despliegue | Sistema | [HU-004](../E-02-identidad-y-acceso/HU-004-primer-administrador-por-configuracion-de-despliegue.md) |
| [FR-018](FR-018-rol-y-estado-en-el-token-de-sesion.md) | Rol y estado en el token de sesión | Sistema | [HU-001](../E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md) |
| [FR-019](FR-019-autorizacion-por-perfil-activo.md) | Autorización por perfil activo | Sistema | [HU-001](../E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md), [HU-003](../E-02-identidad-y-acceso/HU-003-invitar-a-una-persona-y-revocar-invitaciones.md) |
| [FR-020](FR-020-lecturas-filtradas-por-rol-y-dueno.md) | Lecturas filtradas por rol y dueño | Sistema | [HU-001](../E-02-identidad-y-acceso/HU-001-perfiles-rol-actual-y-lecturas-por-rol.md), [HU-109](../E-12-seguridad-auditoria-y-cumplimiento/HU-109-aislamiento-verificado-por-tabla-y-por-funcion.md) |
| [FR-021](FR-021-navegacion-segun-el-rol.md) | Navegación según el rol | Usuario, Analista y Administrador | [HU-006](../E-02-identidad-y-acceso/HU-006-navegacion-y-guardas-segun-el-rol.md) |
| [FR-022](FR-022-mensajes-de-error-de-ingreso.md) | Mensajes de error de ingreso | Usuario, Analista y Administrador | [HU-005](../E-02-identidad-y-acceso/HU-005-ingresar-con-google-en-android-y-web.md) |
| [FR-023](FR-023-cierre-de-sesion.md) | Cierre de sesión | Usuario, Analista y Administrador | [HU-007](../E-02-identidad-y-acceso/HU-007-cerrar-sesion.md), [HU-087](../E-09-tiempo-real-y-notificaciones/HU-087-registrar-mi-dispositivo-para-push.md) |
| [FR-024](FR-024-consulta-del-perfil-propio.md) | Consulta del perfil propio | Usuario, Analista y Administrador | [HU-008](../E-02-identidad-y-acceso/HU-008-ver-mi-perfil.md) |
| [FR-025](FR-025-sincronizacion-del-correo-cambiado-en-workspace.md) | Sincronización del correo cambiado en Workspace | Google Workspace y Sistema | [HU-002](../E-02-identidad-y-acceso/HU-002-alta-solo-con-invitacion-vigente.md) |
| [FR-026](FR-026-sesion-en-almacenamiento-seguro.md) | Sesión en almacenamiento seguro | Usuario, Analista y Administrador | [HU-009](../E-02-identidad-y-acceso/HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md) |
| [FR-027](FR-027-bloqueo-biometrico-de-la-app.md) | Bloqueo biométrico de la app | Usuario, Analista y Administrador | [HU-009](../E-02-identidad-y-acceso/HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md) |
| [FR-028](FR-028-confirmacion-de-acciones-sensibles.md) | Confirmación de acciones sensibles | Usuario, Analista y Administrador | [HU-009](../E-02-identidad-y-acceso/HU-009-sesion-segura-bloqueo-biometrico-y-confirmacion-de-acciones-sensibles.md) |
| [FR-029](FR-029-suspension-de-una-cuenta.md) | Suspensión de una cuenta | Administrador | [HU-010](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md), [HU-067](../E-07-sugerencias-y-decisiones/HU-067-invalidacion-por-precio-y-por-cambio-de-situacion.md), [HU-087](../E-09-tiempo-real-y-notificaciones/HU-087-registrar-mi-dispositivo-para-push.md) |
| [FR-030](FR-030-cupo-congelado-durante-la-suspension.md) | Cupo congelado durante la suspensión | Sistema | [HU-010](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md), [HU-037](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md), [HU-077](../E-08-ejecucion-y-broker/HU-077-proteccion-nativa-en-compras-de-acciones-enteras.md) |
| [FR-031](FR-031-reactivacion-de-una-cuenta.md) | Reactivación de una cuenta | Administrador | [HU-010](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md) |
| [FR-032](FR-032-proteccion-del-ultimo-administrador-y-de-la-accion-sobre-uno-mismo.md) | Protección del último administrador y de la acción sobre uno mismo | Administrador | [HU-010](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md), [HU-011](../E-02-identidad-y-acceso/HU-011-cambiar-el-rol-de-una-cuenta.md), [HU-012](../E-02-identidad-y-acceso/HU-012-dar-de-baja-y-reincorporar-una-cuenta.md) |
| [FR-033](FR-033-cambio-de-rol.md) | Cambio de rol | Administrador | [HU-011](../E-02-identidad-y-acceso/HU-011-cambiar-el-rol-de-una-cuenta.md) |
| [FR-034](FR-034-navegacion-actualizada-al-cambiar-el-rol.md) | Navegación actualizada al cambiar el rol | Usuario, Analista y Administrador | [HU-011](../E-02-identidad-y-acceso/HU-011-cambiar-el-rol-de-una-cuenta.md) |
| [FR-035](FR-035-cierre-de-la-sesion-revocada.md) | Cierre de la sesión revocada | Usuario, Analista y Administrador | [HU-010](../E-02-identidad-y-acceso/HU-010-suspender-y-reactivar-una-cuenta.md) |
| [FR-036](FR-036-baja-de-una-cuenta.md) | Baja de una cuenta | Administrador | [HU-012](../E-02-identidad-y-acceso/HU-012-dar-de-baja-y-reincorporar-una-cuenta.md) |
| [FR-037](FR-037-reincorporacion-de-una-cuenta.md) | Reincorporación de una cuenta | Administrador | [HU-012](../E-02-identidad-y-acceso/HU-012-dar-de-baja-y-reincorporar-una-cuenta.md) |

## E-03 · Fondo y libro contable

| ID | Nombre | Rol o actor | Lo implementan |
|---|---|---|---|
| [FR-038](FR-038-fondo-unico-con-subcuentas.md) | Fondo único con subcuentas | Sistema | [HU-013](../E-03-fondo-y-libro-contable/HU-013-libro-contable-de-doble-partida.md) |
| [FR-039](FR-039-movimientos-de-doble-partida.md) | Movimientos de doble partida | Sistema | [HU-013](../E-03-fondo-y-libro-contable/HU-013-libro-contable-de-doble-partida.md) |
| [FR-040](FR-040-saldos-nunca-negativos.md) | Saldos nunca negativos | Sistema | [HU-013](../E-03-fondo-y-libro-contable/HU-013-libro-contable-de-doble-partida.md) |
| [FR-041](FR-041-libro-inmutable.md) | Libro inmutable | Sistema | [HU-013](../E-03-fondo-y-libro-contable/HU-013-libro-contable-de-doble-partida.md) |
| [FR-042](FR-042-verificacion-diaria-del-libro.md) | Verificación diaria del libro | Sistema | [HU-013](../E-03-fondo-y-libro-contable/HU-013-libro-contable-de-doble-partida.md) |
| [FR-043](FR-043-registro-de-un-aporte.md) | Registro de un aporte | Administrador | [HU-014](../E-03-fondo-y-libro-contable/HU-014-registrar-y-anular-aportes.md) |
| [FR-044](FR-044-anulacion-de-un-aporte-no-confirmado.md) | Anulación de un aporte no confirmado | Administrador | [HU-014](../E-03-fondo-y-libro-contable/HU-014-registrar-y-anular-aportes.md) |
| [FR-045](FR-045-confirmacion-del-aporte-por-conciliacion.md) | Confirmación del aporte por conciliación | Sistema (conciliación) y Broker (Alpaca paper) | [HU-015](../E-03-fondo-y-libro-contable/HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) |
| [FR-046](FR-046-reparto-del-aporte-confirmado.md) | Reparto del aporte confirmado | Sistema | [HU-015](../E-03-fondo-y-libro-contable/HU-015-confirmar-el-aporte-por-conciliacion-y-repartirlo-50-25-25.md) |
| [FR-047](FR-047-fondo-sin-capital.md) | Fondo sin capital | Usuario, Analista y Administrador | [HU-019](../E-03-fondo-y-libro-contable/HU-019-ver-mi-cupo.md), [HU-034](../E-05-motor-de-politicas-y-configuracion/HU-034-encender-y-apagar-los-interruptores-del-fondo.md) |
| [FR-048](FR-048-registro-de-un-retiro.md) | Registro de un retiro | Administrador | [HU-016](../E-03-fondo-y-libro-contable/HU-016-registrar-retiros-de-capital.md) |
| [FR-049](FR-049-cupo-al-aceptar-la-invitacion.md) | Cupo al aceptar la invitación | Sistema | [HU-017](../E-03-fondo-y-libro-contable/HU-017-cupo-al-aceptar-la-invitacion.md) |
| [FR-050](FR-050-asignacion-de-cupo.md) | Asignación de cupo | Administrador | [HU-018](../E-03-fondo-y-libro-contable/HU-018-asignar-y-reducir-cupos.md) |
| [FR-051](FR-051-reduccion-de-cupo.md) | Reducción de cupo | Administrador | [HU-018](../E-03-fondo-y-libro-contable/HU-018-asignar-y-reducir-cupos.md) |
| [FR-052](FR-052-consulta-de-mi-cupo.md) | Consulta de mi cupo | Usuario | [HU-019](../E-03-fondo-y-libro-contable/HU-019-ver-mi-cupo.md) |
| [FR-053](FR-053-resumen-agregado-del-fondo.md) | Resumen agregado del fondo | Usuario, Analista y Administrador | [HU-020](../E-03-fondo-y-libro-contable/HU-020-ver-el-resumen-del-fondo-por-bolsillos.md) |
| [FR-054](FR-054-foto-diaria-de-patrimonio.md) | Foto diaria de patrimonio | Sistema | [HU-021](../E-03-fondo-y-libro-contable/HU-021-foto-diaria-de-patrimonio-y-rendimiento-twr.md) |
| [FR-055](FR-055-rendimiento-ponderado-en-el-tiempo.md) | Rendimiento ponderado en el tiempo | Sistema | [HU-021](../E-03-fondo-y-libro-contable/HU-021-foto-diaria-de-patrimonio-y-rendimiento-twr.md) |
| [FR-056](FR-056-ajuste-contable.md) | Ajuste contable | Administrador | [HU-022](../E-03-fondo-y-libro-contable/HU-022-registrar-ajustes-contables.md) |
| [FR-057](FR-057-reparto-de-la-ganancia-realizada.md) | Reparto de la ganancia realizada | Sistema | [HU-023](../E-03-fondo-y-libro-contable/HU-023-reparto-de-la-ganancia-realizada-y-absorcion-de-perdidas.md) |
| [FR-058](FR-058-costo-y-perdida-de-una-venta.md) | Costo y pérdida de una venta | Sistema | [HU-023](../E-03-fondo-y-libro-contable/HU-023-reparto-de-la-ganancia-realizada-y-absorcion-de-perdidas.md) |
| [FR-059](FR-059-propuesta-de-rebalanceo.md) | Propuesta de rebalanceo | Sistema | [HU-024](../E-03-fondo-y-libro-contable/HU-024-propuesta-de-rebalanceo-tras-el-cierre.md) |
| [FR-060](FR-060-ajuste-por-evento-corporativo.md) | Ajuste por evento corporativo | Administrador | [HU-025](../E-03-fondo-y-libro-contable/HU-025-ajuste-por-split-o-agrupacion-de-acciones.md) |

## E-04 · Datos de mercado

| ID | Nombre | Rol o actor | Lo implementan |
|---|---|---|---|
| [FR-061](FR-061-universo-de-simbolos.md) | Universo de símbolos | Sistema | [HU-026](../E-04-datos-de-mercado/HU-026-universo-del-nasdaq-100-y-carga-historica-de-barras.md) |
| [FR-062](FR-062-carga-historica-de-barras.md) | Carga histórica de barras | Sistema y Datos de mercado (Alpaca) | [HU-026](../E-04-datos-de-mercado/HU-026-universo-del-nasdaq-100-y-carga-historica-de-barras.md) |
| [FR-063](FR-063-calendario-y-reloj-de-mercado.md) | Calendario y reloj de mercado | Sistema y Broker (Alpaca) | [HU-027](../E-04-datos-de-mercado/HU-027-calendario-reloj-y-estado-del-mercado.md) |
| [FR-064](FR-064-estado-del-mercado.md) | Estado del mercado | Usuario, Analista y Administrador | [HU-027](../E-04-datos-de-mercado/HU-027-calendario-reloj-y-estado-del-mercado.md) |
| [FR-065](FR-065-atributos-de-los-activos.md) | Atributos de los activos | Sistema y Broker (Alpaca) | [HU-027](../E-04-datos-de-mercado/HU-027-calendario-reloj-y-estado-del-mercado.md), [HU-085](../E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md) |
| [FR-066](FR-066-ingesta-de-precios.md) | Ingesta de precios | Sistema y Datos de mercado (Alpaca) | [HU-028](../E-04-datos-de-mercado/HU-028-ingesta-de-precios-cada-15-segundos.md) |
| [FR-067](FR-067-descarte-de-precios-invalidos.md) | Descarte de precios inválidos | Sistema | [HU-028](../E-04-datos-de-mercado/HU-028-ingesta-de-precios-cada-15-segundos.md) |
| [FR-068](FR-068-sin-consulta-fuera-de-horario.md) | Sin consulta fuera de horario | Sistema | [HU-028](../E-04-datos-de-mercado/HU-028-ingesta-de-precios-cada-15-segundos.md) |
| [FR-069](FR-069-difusion-de-precios-en-vivo.md) | Difusión de precios en vivo | Sistema | [HU-028](../E-04-datos-de-mercado/HU-028-ingesta-de-precios-cada-15-segundos.md) |
| [FR-070](FR-070-barras-diarias-y-de-minuto.md) | Barras diarias y de minuto | Sistema | [HU-029](../E-04-datos-de-mercado/HU-029-barra-diaria-tras-el-cierre-y-retencion-de-barras-de-minuto.md) |
| [FR-071](FR-071-pantalla-de-mercado.md) | Pantalla de mercado | Usuario, Analista y Administrador | [HU-030](../E-04-datos-de-mercado/HU-030-pantalla-de-mercado-en-vivo.md) |
| [FR-072](FR-072-consulta-de-la-lista-blanca.md) | Consulta de la lista blanca | Usuario, Analista y Administrador | [HU-030](../E-04-datos-de-mercado/HU-030-pantalla-de-mercado-en-vivo.md) |
| [FR-073](FR-073-comparacion-qqq-qld-y-x2-teorico.md) | Comparación QQQ, QLD y ×2 teórico | Usuario, Analista y Administrador | [HU-031](../E-04-datos-de-mercado/HU-031-comparacion-de-qqq-qld-y-x2-teorico.md) |
| [FR-074](FR-074-advertencia-sobre-el-etf-apalancado.md) | Advertencia sobre el ETF apalancado | Usuario, Analista y Administrador | [HU-031](../E-04-datos-de-mercado/HU-031-comparacion-de-qqq-qld-y-x2-teorico.md) |
| [FR-075](FR-075-dato-desactualizado.md) | Dato desactualizado | Usuario, Analista y Administrador | [HU-032](../E-04-datos-de-mercado/HU-032-aviso-de-dato-desactualizado.md) |

## E-05 · Motor de políticas y configuración

| ID | Nombre | Rol o actor | Lo implementan |
|---|---|---|---|
| [FR-076](FR-076-cambio-de-un-parametro.md) | Cambio de un parámetro | Administrador | [HU-033](../E-05-motor-de-politicas-y-configuracion/HU-033-parametros-configurables-con-rango-e-historial.md) |
| [FR-077](FR-077-porcentajes-de-reparto-consistentes.md) | Porcentajes de reparto consistentes | Administrador | [HU-033](../E-05-motor-de-politicas-y-configuracion/HU-033-parametros-configurables-con-rango-e-historial.md) |
| [FR-078](FR-078-consulta-de-parametros-vigentes.md) | Consulta de parámetros vigentes | Usuario, Analista y Administrador | [HU-033](../E-05-motor-de-politicas-y-configuracion/HU-033-parametros-configurables-con-rango-e-historial.md) |
| [FR-079](FR-079-interruptores-del-fondo.md) | Interruptores del fondo | Sistema | [HU-034](../E-05-motor-de-politicas-y-configuracion/HU-034-encender-y-apagar-los-interruptores-del-fondo.md) |
| [FR-080](FR-080-encendido-de-un-interruptor.md) | Encendido de un interruptor | Administrador | [HU-034](../E-05-motor-de-politicas-y-configuracion/HU-034-encender-y-apagar-los-interruptores-del-fondo.md), [HU-040](../E-05-motor-de-politicas-y-configuracion/HU-040-reanudar-el-trading-solo-con-la-conciliacion-en-ok.md) |
| [FR-081](FR-081-salud-de-las-integraciones.md) | Salud de las integraciones | Sistema | [HU-035](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md) |
| [FR-082](FR-082-alerta-por-integracion-caida.md) | Alerta por integración caída | Sistema | [HU-035](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md) |
| [FR-083](FR-083-consulta-de-la-salud.md) | Consulta de la salud | Analista y Administrador | [HU-035](../E-05-motor-de-politicas-y-configuracion/HU-035-salud-de-las-integraciones.md) |
| [FR-084](FR-084-edicion-de-la-lista-blanca.md) | Edición de la lista blanca | Administrador | [HU-036](../E-05-motor-de-politicas-y-configuracion/HU-036-editar-la-lista-blanca.md) |
| [FR-085](FR-085-motor-de-politicas-unico.md) | Motor de políticas único | Sistema | [HU-037](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md), [HU-038](../E-05-motor-de-politicas-y-configuracion/HU-038-motor-de-politicas-completo-en-los-cuatro-momentos.md) |
| [FR-086](FR-086-reglas-de-riesgo-de-las-compras.md) | Reglas de riesgo de las compras | Sistema | [HU-037](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md) |
| [FR-087](FR-087-reglas-de-riesgo-generales.md) | Reglas de riesgo generales | Sistema | [HU-037](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md) |
| [FR-088](FR-088-reglas-de-horario-precio-y-salud.md) | Reglas de horario, precio y salud | Sistema | [HU-037](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md) |
| [FR-089](FR-089-confianza-minima-de-las-sugerencias-de-la-ia.md) | Confianza mínima de las sugerencias de la IA | Sistema | [HU-037](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md) |
| [FR-090](FR-090-registro-de-la-regla-violada.md) | Registro de la regla violada | Sistema | [HU-037](../E-05-motor-de-politicas-y-configuracion/HU-037-motor-de-politicas-reglas-de-la-propuesta.md) |
| [FR-091](FR-091-reglas-que-dependen-de-lo-ya-operado.md) | Reglas que dependen de lo ya operado | Sistema | [HU-038](../E-05-motor-de-politicas-y-configuracion/HU-038-motor-de-politicas-completo-en-los-cuatro-momentos.md) |
| [FR-092](FR-092-copia-congelada-de-parametros.md) | Copia congelada de parámetros | Sistema | [HU-038](../E-05-motor-de-politicas-y-configuracion/HU-038-motor-de-politicas-completo-en-los-cuatro-momentos.md), [HU-058](../E-07-sugerencias-y-decisiones/HU-058-sugerencia-de-compra-para-arriesgadas.md), [HU-059](../E-07-sugerencias-y-decisiones/HU-059-reparto-de-una-senal-de-usuarios-en-sugerencias-por-cupo.md), [HU-075](../E-08-ejecucion-y-broker/HU-075-crear-una-orden-manual-en-mi-cupo.md) |
| [FR-093](FR-093-freno-de-emergencia.md) | Freno de emergencia | Analista y Administrador | [HU-039](../E-05-motor-de-politicas-y-configuracion/HU-039-freno-de-emergencia.md) |
| [FR-094](FR-094-efectos-de-apagar-los-interruptores.md) | Efectos de apagar los interruptores | Sistema | [HU-039](../E-05-motor-de-politicas-y-configuracion/HU-039-freno-de-emergencia.md) |
| [FR-095](FR-095-reanudacion-de-la-operacion.md) | Reanudación de la operación | Administrador | [HU-040](../E-05-motor-de-politicas-y-configuracion/HU-040-reanudar-el-trading-solo-con-la-conciliacion-en-ok.md) |

## E-06 · IA: contexto y decisión

| ID | Nombre | Rol o actor | Lo implementan |
|---|---|---|---|
| [FR-096](FR-096-descarga-de-noticias.md) | Descarga de noticias | Sistema y Noticias (Alpaca News) | [HU-041](../E-06-ia-contexto-y-decision/HU-041-noticias-de-las-candidatas.md) |
| [FR-097](FR-097-generacion-del-contexto-con-deepseek.md) | Generación del contexto con DeepSeek | Sistema y DeepSeek | [HU-042](../E-06-ia-contexto-y-decision/HU-042-contexto-de-deepseek-validado-contra-sus-fuentes.md) |
| [FR-098](FR-098-validacion-del-contexto-contra-sus-fuentes.md) | Validación del contexto contra sus fuentes | Sistema | [HU-042](../E-06-ia-contexto-y-decision/HU-042-contexto-de-deepseek-validado-contra-sus-fuentes.md) |
| [FR-099](FR-099-vigencia-del-contexto.md) | Vigencia del contexto | Sistema | [HU-043](../E-06-ia-contexto-y-decision/HU-043-vigencia-y-regeneracion-del-contexto.md) |
| [FR-100](FR-100-regeneracion-programada-y-a-pedido-del-contexto.md) | Regeneración programada y a pedido del contexto | Sistema, Analista y Administrador | [HU-043](../E-06-ia-contexto-y-decision/HU-043-vigencia-y-regeneracion-del-contexto.md) |
| [FR-101](FR-101-tolerancia-a-fallos-de-noticias-y-de-deepseek.md) | Tolerancia a fallos de noticias y de DeepSeek | Sistema | [HU-043](../E-06-ia-contexto-y-decision/HU-043-vigencia-y-regeneracion-del-contexto.md) |
| [FR-102](FR-102-verificacion-de-calidad-de-datos.md) | Verificación de calidad de datos | Sistema (IA principal) | [HU-044](../E-06-ia-contexto-y-decision/HU-044-calidad-de-datos-metricas-y-puntaje-cuantitativo.md) |
| [FR-103](FR-103-metricas-y-puntaje-cuantitativo.md) | Métricas y puntaje cuantitativo | Sistema (IA principal) | [HU-044](../E-06-ia-contexto-y-decision/HU-044-calidad-de-datos-metricas-y-puntaje-cuantitativo.md) |
| [FR-104](FR-104-seleccion-de-candidatas.md) | Selección de candidatas | Sistema (IA principal) | [HU-044](../E-06-ia-contexto-y-decision/HU-044-calidad-de-datos-metricas-y-puntaje-cuantitativo.md) |
| [FR-105](FR-105-estado-en-etiquetas-para-jev.md) | Estado en etiquetas para JEV | Sistema (IA principal) y JEV | [HU-045](../E-06-ia-contexto-y-decision/HU-045-adaptador-de-jev-y-estado-en-etiquetas.md) |
| [FR-106](FR-106-sin-datos-personales-hacia-las-ias.md) | Sin datos personales hacia las IAs | Sistema | [HU-042](../E-06-ia-contexto-y-decision/HU-042-contexto-de-deepseek-validado-contra-sus-fuentes.md), [HU-045](../E-06-ia-contexto-y-decision/HU-045-adaptador-de-jev-y-estado-en-etiquetas.md) |
| [FR-107](FR-107-consulta-a-jev.md) | Consulta a JEV | Sistema (IA principal) y JEV | [HU-045](../E-06-ia-contexto-y-decision/HU-045-adaptador-de-jev-y-estado-en-etiquetas.md) |
| [FR-108](FR-108-reaccion-a-fallos-de-jev.md) | Reacción a fallos de JEV | Sistema | [HU-045](../E-06-ia-contexto-y-decision/HU-045-adaptador-de-jev-y-estado-en-etiquetas.md) |
| [FR-109](FR-109-ciclo-programado-del-agente.md) | Ciclo programado del agente | Sistema (IA principal) | [HU-046](../E-06-ia-contexto-y-decision/HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md) |
| [FR-110](FR-110-ciclo-por-evento-de-mercado.md) | Ciclo por evento de mercado | Sistema (IA principal) | [HU-046](../E-06-ia-contexto-y-decision/HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md) |
| [FR-111](FR-111-omision-del-ciclo.md) | Omisión del ciclo | Sistema (IA principal) | [HU-046](../E-06-ia-contexto-y-decision/HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md) |
| [FR-112](FR-112-ciclo-manual.md) | Ciclo manual | Administrador | [HU-046](../E-06-ia-contexto-y-decision/HU-046-ciclo-del-agente-programacion-uno-a-la-vez-y-omisiones.md) |
| [FR-113](FR-113-puntaje-compuesto.md) | Puntaje compuesto | Sistema (IA principal) | [HU-047](../E-06-ia-contexto-y-decision/HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) |
| [FR-114](FR-114-reglas-de-decision-de-compra.md) | Reglas de decisión de compra | Sistema (IA principal) | [HU-047](../E-06-ia-contexto-y-decision/HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) |
| [FR-115](FR-115-tamano-stop-y-objetivo-de-la-senal.md) | Tamaño, stop y objetivo de la señal | Sistema (IA principal) | [HU-047](../E-06-ia-contexto-y-decision/HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) |
| [FR-116](FR-116-una-senal-de-compra-por-bolsillo-por-ciclo.md) | Una señal de compra por bolsillo por ciclo | Sistema (IA principal) | [HU-047](../E-06-ia-contexto-y-decision/HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) |
| [FR-117](FR-117-senales-validadas-por-el-motor-de-politicas.md) | Señales validadas por el motor de políticas | Sistema (IA principal) | [HU-047](../E-06-ia-contexto-y-decision/HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) |
| [FR-118](FR-118-registro-de-cada-evaluacion.md) | Registro de cada evaluación | Sistema (IA principal) | [HU-047](../E-06-ia-contexto-y-decision/HU-047-puntaje-compuesto-y-eleccion-de-la-mejor-opcion.md) |
| [FR-119](FR-119-pantalla-oportunidades.md) | Pantalla Oportunidades | Usuario, Analista y Administrador | [HU-048](../E-06-ia-contexto-y-decision/HU-048-pantalla-oportunidades-con-la-explicacion-de-cada-evaluacion.md) |
| [FR-120](FR-120-explicacion-de-cada-decision.md) | Explicación de cada decisión | Sistema (IA principal) | [HU-048](../E-06-ia-contexto-y-decision/HU-048-pantalla-oportunidades-con-la-explicacion-de-cada-evaluacion.md) |
| [FR-121](FR-121-alerta-de-contradiccion-entre-datos-y-contexto.md) | Alerta de contradicción entre datos y contexto | Sistema (IA principal) | [HU-049](../E-06-ia-contexto-y-decision/HU-049-alertas-de-contradiccion-y-de-mercado.md) |
| [FR-122](FR-122-alertas-de-mercado.md) | Alertas de mercado | Sistema (IA principal) | [HU-049](../E-06-ia-contexto-y-decision/HU-049-alertas-de-contradiccion-y-de-mercado.md) |
| [FR-123](FR-123-presupuesto-mensual-de-ia.md) | Presupuesto mensual de IA | Sistema | [HU-050](../E-06-ia-contexto-y-decision/HU-050-presupuesto-mensual-de-ia.md) |
| [FR-124](FR-124-analisis-bajo-demanda.md) | Análisis bajo demanda | Analista | [HU-051](../E-06-ia-contexto-y-decision/HU-051-analisis-bajo-demanda-de-un-simbolo.md) |
| [FR-125](FR-125-opinion-sobre-una-orden-manual.md) | Opinión sobre una orden manual | Usuario | [HU-052](../E-06-ia-contexto-y-decision/HU-052-opinion-de-la-ia-sobre-una-orden-manual.md) |
| [FR-126](FR-126-la-opinion-no-bloquea-la-orden.md) | La opinión no bloquea la orden | Usuario | [HU-052](../E-06-ia-contexto-y-decision/HU-052-opinion-de-la-ia-sobre-una-orden-manual.md) |
| [FR-127](FR-127-senales-de-venta.md) | Señales de venta | Sistema (IA principal) | [HU-053](../E-06-ia-contexto-y-decision/HU-053-senales-de-venta-de-posiciones-abiertas.md) |
| [FR-128](FR-128-versiones-del-prompt-de-contexto.md) | Versiones del prompt de contexto | Administrador | [HU-054](../E-06-ia-contexto-y-decision/HU-054-versiones-del-prompt-de-contexto-y-de-la-configuracion-de-decision.md) |
| [FR-129](FR-129-versiones-de-la-configuracion-de-decision.md) | Versiones de la configuración de decisión | Administrador | [HU-054](../E-06-ia-contexto-y-decision/HU-054-versiones-del-prompt-de-contexto-y-de-la-configuracion-de-decision.md) |
| [FR-130](FR-130-modelos-de-la-lista-permitida.md) | Modelos de la lista permitida | Administrador | [HU-054](../E-06-ia-contexto-y-decision/HU-054-versiones-del-prompt-de-contexto-y-de-la-configuracion-de-decision.md) |
| [FR-131](FR-131-modo-sombra.md) | Modo sombra | Sistema (IA principal) | [HU-055](../E-06-ia-contexto-y-decision/HU-055-modo-sombra-de-una-configuracion-candidata.md) |
| [FR-132](FR-132-evaluacion-de-sugerencias-y-candidatas.md) | Evaluación de sugerencias y candidatas | Sistema | [HU-056](../E-06-ia-contexto-y-decision/HU-056-evaluacion-de-sugerencias-y-candidatas-tras-el-cierre.md) |
| [FR-133](FR-133-desempeno-y-calibracion-de-la-ia.md) | Desempeño y calibración de la IA | Analista y Administrador | [HU-057](../E-06-ia-contexto-y-decision/HU-057-desempeno-y-calibracion-de-la-ia.md) |

## E-07 · Sugerencias y decisiones

| ID | Nombre | Rol o actor | Lo implementan |
|---|---|---|---|
| [FR-134](FR-134-sugerencia-de-compra-en-arriesgadas.md) | Sugerencia de compra en Arriesgadas | Sistema | [HU-058](../E-07-sugerencias-y-decisiones/HU-058-sugerencia-de-compra-para-arriesgadas.md) |
| [FR-135](FR-135-marca-de-doble-aprobacion.md) | Marca de doble aprobación | Sistema | [HU-058](../E-07-sugerencias-y-decisiones/HU-058-sugerencia-de-compra-para-arriesgadas.md) |
| [FR-136](FR-136-reparto-de-la-senal-de-usuarios-en-cupos.md) | Reparto de la señal de Usuarios en cupos | Sistema | [HU-059](../E-07-sugerencias-y-decisiones/HU-059-reparto-de-una-senal-de-usuarios-en-sugerencias-por-cupo.md) |
| [FR-137](FR-137-tamano-de-la-orden-sugerida.md) | Tamaño de la orden sugerida | Sistema | [HU-058](../E-07-sugerencias-y-decisiones/HU-058-sugerencia-de-compra-para-arriesgadas.md), [HU-059](../E-07-sugerencias-y-decisiones/HU-059-reparto-de-una-senal-de-usuarios-en-sugerencias-por-cupo.md) |
| [FR-138](FR-138-sugerencias-de-venta.md) | Sugerencias de venta | Sistema | [HU-060](../E-07-sugerencias-y-decisiones/HU-060-sugerencias-de-venta-por-subcuenta.md) |
| [FR-139](FR-139-vencimiento-y-precios-de-la-sugerencia.md) | Vencimiento y precios de la sugerencia | Sistema | [HU-058](../E-07-sugerencias-y-decisiones/HU-058-sugerencia-de-compra-para-arriesgadas.md), [HU-059](../E-07-sugerencias-y-decisiones/HU-059-reparto-de-una-senal-de-usuarios-en-sugerencias-por-cupo.md) |
| [FR-140](FR-140-bandeja-de-sugerencias-del-usuario.md) | Bandeja de sugerencias del Usuario | Usuario | [HU-061](../E-07-sugerencias-y-decisiones/HU-061-mis-sugerencias-bandeja-y-detalle-con-explicacion.md) |
| [FR-141](FR-141-detalle-de-la-sugerencia.md) | Detalle de la sugerencia | Usuario y Analista | [HU-061](../E-07-sugerencias-y-decisiones/HU-061-mis-sugerencias-bandeja-y-detalle-con-explicacion.md), [HU-064](../E-07-sugerencias-y-decisiones/HU-064-bandeja-de-riesgo-del-analista.md) |
| [FR-142](FR-142-aprobacion-de-una-sugerencia-de-mi-cupo.md) | Aprobación de una sugerencia de mi cupo | Usuario | [HU-062](../E-07-sugerencias-y-decisiones/HU-062-aprobar-una-sugerencia-de-mi-cupo.md) |
| [FR-143](FR-143-retencion-de-fondos-al-aprobar.md) | Retención de fondos al aprobar | Sistema | [HU-062](../E-07-sugerencias-y-decisiones/HU-062-aprobar-una-sugerencia-de-mi-cupo.md), [HU-065](../E-07-sugerencias-y-decisiones/HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) |
| [FR-144](FR-144-rechazo-de-una-sugerencia-con-motivo.md) | Rechazo de una sugerencia con motivo | Usuario, Analista y Administrador | [HU-063](../E-07-sugerencias-y-decisiones/HU-063-rechazar-una-sugerencia-con-motivo.md) |
| [FR-145](FR-145-decision-unica-e-idempotente.md) | Decisión única e idempotente | Sistema | [HU-062](../E-07-sugerencias-y-decisiones/HU-062-aprobar-una-sugerencia-de-mi-cupo.md), [HU-063](../E-07-sugerencias-y-decisiones/HU-063-rechazar-una-sugerencia-con-motivo.md) |
| [FR-146](FR-146-bandeja-de-riesgo.md) | Bandeja de riesgo | Analista (Administrador en solo lectura) | [HU-064](../E-07-sugerencias-y-decisiones/HU-064-bandeja-de-riesgo-del-analista.md) |
| [FR-147](FR-147-decision-de-un-analista-sobre-arriesgadas.md) | Decisión de un Analista sobre Arriesgadas | Analista | [HU-065](../E-07-sugerencias-y-decisiones/HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) |
| [FR-148](FR-148-doble-aprobacion.md) | Doble aprobación | Analista | [HU-065](../E-07-sugerencias-y-decisiones/HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) |
| [FR-149](FR-149-anulacion-de-la-primera-aprobacion.md) | Anulación de la primera aprobación | Sistema | [HU-065](../E-07-sugerencias-y-decisiones/HU-065-decidir-en-arriesgadas-con-doble-aprobacion.md) |
| [FR-150](FR-150-vencimiento-por-tiempo.md) | Vencimiento por tiempo | Sistema | [HU-066](../E-07-sugerencias-y-decisiones/HU-066-vencimiento-por-tiempo-y-aviso-previo.md) |
| [FR-151](FR-151-aviso-de-sugerencia-por-vencer.md) | Aviso de sugerencia por vencer | Sistema | [HU-066](../E-07-sugerencias-y-decisiones/HU-066-vencimiento-por-tiempo-y-aviso-previo.md) |
| [FR-152](FR-152-invalidacion-por-banda-de-precio.md) | Invalidación por banda de precio | Sistema | [HU-067](../E-07-sugerencias-y-decisiones/HU-067-invalidacion-por-precio-y-por-cambio-de-situacion.md) |
| [FR-153](FR-153-invalidacion-por-cambio-de-situacion.md) | Invalidación por cambio de situación | Sistema | [HU-067](../E-07-sugerencias-y-decisiones/HU-067-invalidacion-por-precio-y-por-cambio-de-situacion.md) |
| [FR-154](FR-154-pausa-de-la-recepcion-de-sugerencias.md) | Pausa de la recepción de sugerencias | Usuario | [HU-068](../E-07-sugerencias-y-decisiones/HU-068-pausar-la-recepcion-de-sugerencias.md) |
| [FR-155](FR-155-solicitud-de-liquidacion-de-un-cupo.md) | Solicitud de liquidación de un cupo | Administrador | [HU-069](../E-07-sugerencias-y-decisiones/HU-069-solicitar-la-liquidacion-de-un-cupo.md) |
| [FR-156](FR-156-decision-de-las-ventas-de-liquidacion.md) | Decisión de las ventas de liquidación | Analista | [HU-070](../E-07-sugerencias-y-decisiones/HU-070-aprobar-las-ventas-de-liquidacion.md) |
| [FR-157](FR-157-decision-de-un-rebalanceo.md) | Decisión de un rebalanceo | Administrador | [HU-071](../E-07-sugerencias-y-decisiones/HU-071-aprobar-o-rechazar-un-rebalanceo.md) |

## E-08 · Ejecución y broker

| ID | Nombre | Rol o actor | Lo implementan |
|---|---|---|---|
| [FR-158](FR-158-adaptador-del-broker.md) | Adaptador del broker | Sistema y Broker (Alpaca paper) | [HU-072](../E-08-ejecucion-y-broker/HU-072-adaptador-del-broker-para-ordenes.md) |
| [FR-159](FR-159-la-ia-no-ejecuta.md) | La IA no ejecuta | Sistema | [HU-072](../E-08-ejecucion-y-broker/HU-072-adaptador-del-broker-para-ordenes.md) |
| [FR-160](FR-160-envio-de-ordenes-desde-una-cola.md) | Envío de órdenes desde una cola | Sistema (ejecutor de órdenes) | [HU-073](../E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md) |
| [FR-161](FR-161-envio-idempotente.md) | Envío idempotente | Sistema (ejecutor de órdenes) | [HU-073](../E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md) |
| [FR-162](FR-162-tipos-de-orden.md) | Tipos de orden | Sistema (ejecutor de órdenes) | [HU-073](../E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md) |
| [FR-163](FR-163-tratamiento-de-los-errores-del-broker.md) | Tratamiento de los errores del broker | Sistema (ejecutor de órdenes) | [HU-073](../E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md) |
| [FR-164](FR-164-reintentos-de-la-cola-de-ordenes.md) | Reintentos de la cola de órdenes | Sistema | [HU-073](../E-08-ejecucion-y-broker/HU-073-enviar-al-broker-las-ordenes-aprobadas.md) |
| [FR-165](FR-165-sincronizacion-de-ordenes.md) | Sincronización de órdenes | Sistema y Broker (Alpaca paper) | [HU-074](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) |
| [FR-166](FR-166-aplicacion-de-llenados.md) | Aplicación de llenados | Sistema | [HU-074](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) |
| [FR-167](FR-167-tiempo-maximo-de-llenado.md) | Tiempo máximo de llenado | Sistema | [HU-074](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) |
| [FR-168](FR-168-cierre-de-la-orden-y-de-su-sugerencia.md) | Cierre de la orden y de su sugerencia | Sistema | [HU-074](../E-08-ejecucion-y-broker/HU-074-sincronizar-ordenes-y-aplicar-llenados.md) |
| [FR-169](FR-169-orden-manual.md) | Orden manual | Usuario | [HU-075](../E-08-ejecucion-y-broker/HU-075-crear-una-orden-manual-en-mi-cupo.md) |
| [FR-170](FR-170-orden-manual-sin-duplicados.md) | Orden manual sin duplicados | Usuario | [HU-075](../E-08-ejecucion-y-broker/HU-075-crear-una-orden-manual-en-mi-cupo.md) |
| [FR-171](FR-171-cancelacion-de-una-orden-propia.md) | Cancelación de una orden propia | Usuario | [HU-076](../E-08-ejecucion-y-broker/HU-076-ver-mis-ordenes-y-cancelar-una-que-no-se-ha-llenado.md) |
| [FR-172](FR-172-proteccion-nativa.md) | Protección nativa | Sistema y Broker (Alpaca paper) | [HU-077](../E-08-ejecucion-y-broker/HU-077-proteccion-nativa-en-compras-de-acciones-enteras.md) |
| [FR-173](FR-173-venta-de-una-posicion-con-proteccion-nativa.md) | Venta de una posición con protección nativa | Sistema | [HU-077](../E-08-ejecucion-y-broker/HU-077-proteccion-nativa-en-compras-de-acciones-enteras.md) |
| [FR-174](FR-174-proteccion-virtual.md) | Protección virtual | Sistema | [HU-078](../E-08-ejecucion-y-broker/HU-078-proteccion-virtual-en-compras-fraccionales.md) |
| [FR-175](FR-175-protecciones-sin-aprobacion-ni-freno.md) | Protecciones sin aprobación ni freno | Sistema | [HU-077](../E-08-ejecucion-y-broker/HU-077-proteccion-nativa-en-compras-de-acciones-enteras.md), [HU-078](../E-08-ejecucion-y-broker/HU-078-proteccion-virtual-en-compras-fraccionales.md) |
| [FR-176](FR-176-alerta-de-proteccion-virtual-sin-vigilancia.md) | Alerta de protección virtual sin vigilancia | Sistema | [HU-078](../E-08-ejecucion-y-broker/HU-078-proteccion-virtual-en-compras-fraccionales.md) |
| [FR-177](FR-177-llenado-parcial-de-un-bracket.md) | Llenado parcial de un bracket | Sistema | [HU-078](../E-08-ejecucion-y-broker/HU-078-proteccion-virtual-en-compras-fraccionales.md) |
| [FR-178](FR-178-ajuste-de-la-proteccion.md) | Ajuste de la protección | Usuario y Analista | [HU-079](../E-08-ejecucion-y-broker/HU-079-ajustar-el-stop-y-el-objetivo-de-una-posicion.md) |
| [FR-179](FR-179-conciliacion-con-el-broker.md) | Conciliación con el broker | Sistema y Broker (Alpaca paper) | [HU-080](../E-08-ejecucion-y-broker/HU-080-conciliacion-completa-con-pausa-automatica.md) |
| [FR-180](FR-180-excedente-no-asignado.md) | Excedente no asignado | Sistema | [HU-080](../E-08-ejecucion-y-broker/HU-080-conciliacion-completa-con-pausa-automatica.md) |
| [FR-181](FR-181-pausa-automatica-por-descuadre-critico.md) | Pausa automática por descuadre crítico | Sistema | [HU-080](../E-08-ejecucion-y-broker/HU-080-conciliacion-completa-con-pausa-automatica.md) |
| [FR-182](FR-182-revision-de-un-descuadre.md) | Revisión de un descuadre | Administrador | [HU-081](../E-08-ejecucion-y-broker/HU-081-revisar-un-descuadre-y-lanzar-una-conciliacion.md) |
| [FR-183](FR-183-conciliacion-manual.md) | Conciliación manual | Administrador | [HU-081](../E-08-ejecucion-y-broker/HU-081-revisar-un-descuadre-y-lanzar-una-conciliacion.md) |
| [FR-184](FR-184-consulta-de-conciliaciones.md) | Consulta de conciliaciones | Analista y Administrador | [HU-081](../E-08-ejecucion-y-broker/HU-081-revisar-un-descuadre-y-lanzar-una-conciliacion.md) |
| [FR-185](FR-185-renovacion-de-protecciones-nativas.md) | Renovación de protecciones nativas | Sistema | [HU-082](../E-08-ejecucion-y-broker/HU-082-renovar-las-protecciones-nativas-a-los-80-dias.md) |

## E-09 · Tiempo real y notificaciones

| ID | Nombre | Rol o actor | Lo implementan |
|---|---|---|---|
| [FR-186](FR-186-canales-privados-por-rol.md) | Canales privados por rol | Sistema | [HU-083](../E-09-tiempo-real-y-notificaciones/HU-083-canales-privados-de-tiempo-real.md) |
| [FR-187](FR-187-eventos-sin-montos.md) | Eventos sin montos | Sistema | [HU-083](../E-09-tiempo-real-y-notificaciones/HU-083-canales-privados-de-tiempo-real.md) |
| [FR-188](FR-188-actualizacion-en-vivo-con-foto-y-eventos.md) | Actualización en vivo con foto y eventos | Usuario, Analista y Administrador | [HU-084](../E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md) |
| [FR-189](FR-189-indicador-de-conexion.md) | Indicador de conexión | Usuario, Analista y Administrador | [HU-084](../E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md) |
| [FR-190](FR-190-reloj-corregido-con-el-servidor.md) | Reloj corregido con el servidor | Usuario, Analista y Administrador | [HU-084](../E-09-tiempo-real-y-notificaciones/HU-084-gestor-de-tiempo-real-en-la-app.md) |
| [FR-191](FR-191-alertas-por-audiencia.md) | Alertas por audiencia | Usuario, Analista y Administrador | [HU-085](../E-09-tiempo-real-y-notificaciones/HU-085-alertas-del-sistema-por-audiencia.md) |
| [FR-192](FR-192-bandeja-de-notificaciones.md) | Bandeja de notificaciones | Usuario, Analista y Administrador | [HU-086](../E-09-tiempo-real-y-notificaciones/HU-086-bandeja-de-notificaciones.md) |
| [FR-193](FR-193-registro-del-dispositivo.md) | Registro del dispositivo | Usuario, Analista y Administrador | [HU-087](../E-09-tiempo-real-y-notificaciones/HU-087-registrar-mi-dispositivo-para-push.md) |
| [FR-194](FR-194-envio-de-push.md) | Envío de push | Sistema y Firebase (FCM) | [HU-088](../E-09-tiempo-real-y-notificaciones/HU-088-recibir-avisos-por-push.md) |
| [FR-195](FR-195-preferencias-de-notificacion.md) | Preferencias de notificación | Usuario, Analista y Administrador | [HU-089](../E-09-tiempo-real-y-notificaciones/HU-089-elegir-que-avisos-recibo-por-push.md) |
| [FR-196](FR-196-apertura-desde-la-notificacion.md) | Apertura desde la notificación | Usuario, Analista y Administrador | [HU-090](../E-09-tiempo-real-y-notificaciones/HU-090-abrir-la-app-desde-la-notificacion.md) |
| [FR-197](FR-197-aviso-dentro-de-la-app.md) | Aviso dentro de la app | Usuario, Analista y Administrador | [HU-090](../E-09-tiempo-real-y-notificaciones/HU-090-abrir-la-app-desde-la-notificacion.md) |

## E-10 · Cartera y reportes

| ID | Nombre | Rol o actor | Lo implementan |
|---|---|---|---|
| [FR-198](FR-198-posiciones-valoradas-de-mi-cupo.md) | Posiciones valoradas de mi cupo | Usuario | [HU-091](../E-10-cartera-y-reportes/HU-091-ver-mis-posiciones-y-sus-protecciones.md) |
| [FR-199](FR-199-protecciones-visibles.md) | Protecciones visibles | Usuario y Analista | [HU-091](../E-10-cartera-y-reportes/HU-091-ver-mis-posiciones-y-sus-protecciones.md), [HU-092](../E-10-cartera-y-reportes/HU-092-ver-el-detalle-del-fondo.md) |
| [FR-200](FR-200-detalle-del-fondo-para-supervision.md) | Detalle del fondo para supervisión | Analista y Administrador | [HU-092](../E-10-cartera-y-reportes/HU-092-ver-el-detalle-del-fondo.md) |
| [FR-201](FR-201-historial-de-operaciones.md) | Historial de operaciones | Usuario, Analista y Administrador | [HU-093](../E-10-cartera-y-reportes/HU-093-ver-el-historial-de-operaciones.md) |
| [FR-202](FR-202-rendimiento-y-comparacion.md) | Rendimiento y comparación | Usuario, Analista y Administrador | [HU-094](../E-10-cartera-y-reportes/HU-094-ver-el-rendimiento-y-compararlo-con-el-nasdaq-100.md) |
| [FR-203](FR-203-exportacion-csv.md) | Exportación CSV | Usuario, Analista y Administrador | [HU-095](../E-10-cartera-y-reportes/HU-095-exportar-reportes-en-csv.md), [HU-117](../E-13-transicion-desde-la-v2/HU-117-exportador-de-reportes-de-la-v2-con-sus-pruebas.md) |
| [FR-204](FR-204-advertencia-de-paper-trading.md) | Advertencia de paper trading | Usuario, Analista y Administrador | [HU-095](../E-10-cartera-y-reportes/HU-095-exportar-reportes-en-csv.md) |
| [FR-205](FR-205-reporte-diario-al-administrador.md) | Reporte diario al Administrador | Administrador | [HU-096](../E-10-cartera-y-reportes/HU-096-reporte-diario-al-administrador.md) |

## E-11 · Administración

| ID | Nombre | Rol o actor | Lo implementan |
|---|---|---|---|
| [FR-206](FR-206-seccion-de-administracion.md) | Sección de Administración | Administrador | [HU-097](../E-11-administracion/HU-097-seccion-de-administracion-y-guia-de-primeros-pasos.md) |
| [FR-207](FR-207-guia-de-primeros-pasos.md) | Guía de primeros pasos | Administrador | [HU-097](../E-11-administracion/HU-097-seccion-de-administracion-y-guia-de-primeros-pasos.md) |
| [FR-208](FR-208-pantalla-de-usuarios-e-invitaciones.md) | Pantalla de usuarios e invitaciones | Administrador | [HU-098](../E-11-administracion/HU-098-pantalla-de-usuarios-e-invitaciones.md) |
| [FR-209](FR-209-pantalla-de-capital.md) | Pantalla de capital | Administrador | [HU-099](../E-11-administracion/HU-099-pantalla-de-capital.md) |
| [FR-210](FR-210-pantalla-de-cupos.md) | Pantalla de cupos | Administrador | [HU-100](../E-11-administracion/HU-100-pantalla-de-cupos.md) |
| [FR-211](FR-211-pantalla-de-parametros.md) | Pantalla de parámetros | Administrador | [HU-101](../E-11-administracion/HU-101-pantalla-de-parametros-e-interruptores.md) |
| [FR-212](FR-212-pantalla-de-interruptores.md) | Pantalla de interruptores | Administrador | [HU-101](../E-11-administracion/HU-101-pantalla-de-parametros-e-interruptores.md) |
| [FR-213](FR-213-pantalla-de-lista-blanca.md) | Pantalla de lista blanca | Administrador | [HU-102](../E-11-administracion/HU-102-pantalla-de-lista-blanca.md) |
| [FR-214](FR-214-pantalla-de-salud-e-integraciones.md) | Pantalla de salud e integraciones | Administrador (Analista en solo lectura) | [HU-103](../E-11-administracion/HU-103-pantalla-de-salud-e-integraciones.md) |
| [FR-215](FR-215-pantalla-de-conciliaciones.md) | Pantalla de conciliaciones | Administrador (Analista en solo lectura) | [HU-104](../E-11-administracion/HU-104-pantalla-de-conciliaciones.md) |
| [FR-216](FR-216-pantalla-de-rebalanceos.md) | Pantalla de rebalanceos | Administrador | [HU-105](../E-11-administracion/HU-105-pantalla-de-rebalanceos.md) |
| [FR-217](FR-217-pantalla-de-prompts-y-configuraciones.md) | Pantalla de prompts y configuraciones | Administrador (Analista en solo lectura) | [HU-106](../E-11-administracion/HU-106-pantalla-de-prompts-y-configuraciones-de-decision.md) |

## E-12 · Seguridad, auditoría y cumplimiento

| ID | Nombre | Rol o actor | Lo implementan |
|---|---|---|---|
| [FR-218](FR-218-bitacora-de-acciones-sensibles.md) | Bitácora de acciones sensibles | Sistema | [HU-107](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md), [HU-108](../E-12-seguridad-auditoria-y-cumplimiento/HU-108-consultar-y-exportar-la-bitacora.md) |
| [FR-219](FR-219-bitacora-inmutable-y-encadenada.md) | Bitácora inmutable y encadenada | Sistema | [HU-107](../E-12-seguridad-auditoria-y-cumplimiento/HU-107-bitacora-inmutable-con-cadena-de-hash.md) |
| [FR-220](FR-220-verificacion-semanal-de-la-cadena.md) | Verificación semanal de la cadena | Sistema | [HU-110](../E-12-seguridad-auditoria-y-cumplimiento/HU-110-verificacion-semanal-de-la-cadena-de-hash.md) |
| [FR-221](FR-221-consulta-de-la-bitacora.md) | Consulta de la bitácora | Administrador | [HU-108](../E-12-seguridad-auditoria-y-cumplimiento/HU-108-consultar-y-exportar-la-bitacora.md) |
| [FR-222](FR-222-aislamiento-verificado-por-tabla-y-por-funcion.md) | Aislamiento verificado por tabla y por función | Sistema | [HU-109](../E-12-seguridad-auditoria-y-cumplimiento/HU-109-aislamiento-verificado-por-tabla-y-por-funcion.md), [HU-114](../E-12-seguridad-auditoria-y-cumplimiento/HU-114-lista-de-verificacion-antes-de-abrir-el-mvp-al-equipo.md) |
| [FR-223](FR-223-aviso-de-privacidad.md) | Aviso de privacidad | Usuario, Analista y Administrador | [HU-111](../E-12-seguridad-auditoria-y-cumplimiento/HU-111-avisos-de-privacidad-y-de-no-asesoria.md) |
| [FR-224](FR-224-aviso-de-que-no-es-asesoria-financiera.md) | Aviso de que no es asesoría financiera | Usuario y Analista | [HU-061](../E-07-sugerencias-y-decisiones/HU-061-mis-sugerencias-bandeja-y-detalle-con-explicacion.md), [HU-111](../E-12-seguridad-auditoria-y-cumplimiento/HU-111-avisos-de-privacidad-y-de-no-asesoria.md) |
| [FR-225](FR-225-retencion-de-datos.md) | Retención de datos | Sistema | [HU-112](../E-12-seguridad-auditoria-y-cumplimiento/HU-112-retencion-de-datos-y-vigilancia-del-tamano-de-la-base.md) |
| [FR-226](FR-226-vigilancia-del-tamano-de-la-base-de-datos.md) | Vigilancia del tamaño de la base de datos | Sistema | [HU-112](../E-12-seguridad-auditoria-y-cumplimiento/HU-112-retencion-de-datos-y-vigilancia-del-tamano-de-la-base.md) |

## E-13 · Transición desde la v2

| ID | Nombre | Rol o actor | Lo implementan |
|---|---|---|---|
| [FR-227](FR-227-linea-x2-teorico.md) | Línea ×2 teórico | Sistema | [HU-115](../E-13-transicion-desde-la-v2/HU-115-motor-x2-teorico-de-la-v2-con-sus-pruebas.md) |
