# Plan: HU-073 · Enviar al broker las órdenes aprobadas

**Rama**: `073-enviar-ordenes-al-broker` (apilada sobre HU-072, HU-034, HU-035 y HU-037) · **Módulos**: M-10 · **Fuentes**: `docs/06` §5.4 y §8, `docs/08` §2, `docs/05` §6-§8, `docs/10` §5 y §10, `docs/02` RR-12.

- **BD** (`20261110130000`): tipos `lado`, `origen_orden`, `clase_orden`, `tipo_orden`, `estado_orden`; `ordenes` y `ordenes_eventos` con RLS (lectura de supervisión y del dueño del cupo) y evento `orden` (sin montos); cola `ordenes_por_enviar` que llena un trigger al insertar; `private.cambiar_estado_orden` (estado + evento + liberación de retención).
- **BD** (`20261110130001`): `leer_ordenes_por_enviar` (archiva y deja `error_envio` al 5.º intento), `confirmar_orden_por_enviar`, `hay_ordenes_por_enviar`, `registrar_respuesta_envio`, `registrar_error_envio`; trabajo `barrer_ejecutor` (10 s).
- **BD** (`20261110130002`): `tomar_orden_para_envio`: bloquea, devuelve `enviar | consultar | fallida | ya_resuelta`; revalida con `private.validar_operacion` + banda RR-12.
- **Función** `ejecutor-ordenes`: lee la cola, toma, envía con el adaptador (HU-072), cierra el envío, registra la salud de `alpaca_trading` (HU-035) y confirma el mensaje. Solo secreto interno.
- **Sin app**: la historia no tiene pantallas (la pantalla de órdenes es de HU-075 y siguientes).

Decisiones sin regla explícita en `docs/`: ver "Supuestos" de la spec.

Pruebas: pgTAP `19_ordenes_y_envio_test.sql` (55); `deno test ejecutor-ordenes` (18).
