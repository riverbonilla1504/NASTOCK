# Contrato: cambiar rol

Fuente: docs/06 §8.1, `cambiar_rol(usuario_id, rol)`. Actor: Administrador activo (PM-51).

## Entrada

UUID de cuenta destino y rol del enum `public.rol_app`; actor obtenido de la sesión. Usar parámetros SQL `p_usuario_id`, `p_rol` conforme al estilo existente y documentarlos para HU-098. La historia no define un retorno de negocio.

## Resultados y errores

- CA-1: cupo en cero al pasar a Usuario; auditoría `cuenta.rol_cambiado`.
- CA-2: efectivo devuelto y cupo cerrado al dejar de ser Usuario.
- CA-3: `CUPO_CON_POSICIONES` si hay posiciones u órdenes vivas.
- CA-4: `ULTIMO_ADMIN` y `AUTO_ACCION`; probar explícitamente condiciones coincidentes sin debilitar ninguna protección.
- CA-5: `NO_AUTORIZADO` para Usuario/Analista. Seguir las convenciones existentes para sesión inválida y destino inexistente.

## Evento

`perfil_actualizado` en `usuario:{uuid}` del destino; carga mínima según docs/09 §4. La app renueva el token mediante Auth y recalcula guardas y suscripciones. El servidor aplica el rol nuevo desde la transacción aunque siga vigente el JWT anterior.
