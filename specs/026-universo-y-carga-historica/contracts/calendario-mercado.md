# Contrato: Edge Function `calendario-mercado` (carga inicial)

`docs/05` §6: la invoca el trabajo diario de HU-027 o una persona con el secreto interno; tiempo máximo 120 s. Esta historia entrega solo la **carga inicial de barras históricas**; el calendario, el reloj y los atributos de los activos son de HU-027.

## Solicitud

`POST /functions/v1/calendario-mercado` con la cabecera `x-secreto-interno`. El cuerpo se ignora. `verify_jwt = false` en `config.toml`.

## Autenticación (`_shared/auth.ts`)

| Llamada | Respuesta |
|---|---|
| Secreto interno correcto | Sigue |
| Secreto incorrecto, sin sesión | `403 {"codigo":"NO_AUTORIZADO"}` |
| Sin secreto ni sesión, o con un JWT | `401 {"codigo":"SESION_INVALIDA"}` (esta función no acepta personas) |
| Otro método que POST | `405` |

## Pasos

1. `ahora = private.ahora()`; `hasta` = ayer y `desde` = hoy − 2 años, en hora de Nueva York.
2. `private.simbolos_sin_historia(desde)`.
3. En lotes de 20: `mercado.barras({simbolos, desde, hasta})` → `private.guardar_barras_diarias(barras)`.
4. Pasado el presupuesto de tiempo (100 s), no empieza otro lote y devuelve los símbolos que faltan.

## Respuesta `200`

```json
{ "desde": "2024-11-05", "hasta": "2026-11-04",
  "simbolos_consultados": 104, "barras_recibidas": 52416, "barras_nuevas": 52416,
  "barras_descartadas": 0, "pendientes": [] }
```

Una segunda ejecución devuelve `simbolos_consultados: 0` y `barras_nuevas: 0` (CA-3). Si el proveedor falla: `502 {"codigo":"INTEGRACION_CAIDA","pendientes":[…]}` (código de `docs/06` §9), con lo ya guardado conservado.

## Pruebas (`deno test`, con base y proveedor falsos)

- Carga solo los símbolos sin historia; lotes de 20; ayer y dos años en hora de Nueva York (incluida una hora de las 02:00 UTC, que en Nueva York sigue siendo el día anterior).
- Segunda ejecución: no pide nada y no duplica.
- Presupuesto de tiempo agotado: devuelve `pendientes`.
- Fallo del proveedor: `502` con lo guardado.
- Autenticación según la tabla de arriba.
