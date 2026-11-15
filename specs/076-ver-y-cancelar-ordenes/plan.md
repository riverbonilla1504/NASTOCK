# Plan: HU-076

**Rama**: `076-ver-y-cancelar-ordenes` · **Issue**: #99 · **Módulo**: M-10.

## Contexto y constitución

SQL Postgres/Supabase, Deno 2 y Flutter 3.47.9/Riverpod; sin dependencias nuevas. Docs/08 §2, docs/10 §7, docs/06 §8.1 y PM-13. Docs primero: historial 3.30, aprobado por Yul Bastidas. Escribir solo por RPC, no liberar efectivo desde Flutter, mantener RLS y aplicar estados mediante el motor existente. Se conservan los cinco CA y FR-171. Pruebas pgTAP, Deno, widget y E2E obligatorias.

## Investigación y contrato

`sincronizar-ordenes` ya envía cancelaciones por tiempo y luego consulta/aplica el estado del broker. Ampliar su consulta a `private.ordenes_por_cancelar()` reúne tiempo y solicitudes de usuario sin duplicar órdenes. `cancelar_orden(p_id)` valida sesión, dueño y estado bajo bloqueo; una creada se cancela antes de enviarse, las demás registran solicitud y despiertan al sincronizador. Reintentar la misma solicitud es idempotente. `aplicar_llenado` conserva los parciales, determina el estado final y libera retención; `pending_cancel` no es terminal. Un trigger audita `orden.cancelada` cuando el estado confirmado cambia. Si el llenado gana, no se registra cancelación falsa.

## Modelo y estructura

Agregar `cancelacion_solicitada_en` y `cancelacion_solicitada_por` a órdenes. Mantener índice/RLS existentes. Migración `20261115140000_cancelar_orden.sql`; pruebas `25_cancelar_orden_test.sql`; manejador y pruebas de `supabase/functions/sincronizar-ordenes/`; dominio/repositorio/provider/pantalla en `lib/features/ordenes/`. Entrada desde Mi cupo a `/cupo/ordenes`, restringida por la guarda del destino Usuario. Foto + eventos `orden` actualiza la lista. No agregar destino principal.

## Diseño y validación

Reutilizar tokens de DESIGN.md y Tarjeta, BarraSuperior, estados comunes y diálogo de confirmación. Mostrar estado, cantidad llenada/total, solicitud pendiente y llenado que ganó la carrera. Botón solo mientras se puede solicitar; el servidor vuelve a validar. Probar carga, vacío, fallo, parcial, pendiente y final en 360 dp. Sin comandos Impeccable conectados: revisión de forma/auditoría/pulido sobre componentes existentes.

## Orden

Contrato/documentación → migración y pruebas SQL → sincronizador y Deno → app y widget → E2E/mapa → verificación completa y CI. No integrar con pruebas pendientes o rojas.
