# Plan de implementación: HU-033 · Parámetros configurables con rango e historial

**Rama**: `033-parametros-configurables` | **Fecha**: 2026-11-08 | **Especificación**: [spec.md](spec.md)

## Resumen

El Administrador cambia parámetros del catálogo de `docs/02` §10 por la RPC `actualizar_parametro(clave, valor, motivo)`, que valida tipo y rango, guarda el cambio en `parametros_historial`, audita `parametro.cambiado` y publica `parametro` en el canal `admin`. Los tres `reparto.pct_*` se cambian juntos con la clave `reparto` y deben sumar 100. Por capas, cada una con sus pruebas: (1) migración: catálogo completo en `parametros` y tabla `parametros_historial` con RLS solo Administrador; (2) RPC `actualizar_parametro` y función `private` de validación; (3) migración que hace que `private.margenes_de_compra()` lea `parametros`. Sin Edge Functions ni app.

## Contexto técnico

SQL/PL/pgSQL en Supabase local; pgTAP en `supabase/tests/database/` (`10_politicas_*`). Módulo: M-08 (`docs/17`); toca M-07 (`margenes_de_compra`). Reglas: PM-54, PM-06, RN-02, `docs/02` §10, `docs/06` §5.6 y §6, `docs/09` §3-§4, `docs/11` §4.1. No cambia `docs/` salvo documentar nombres en `docs/17` y la frase de `docs/06` §6 sobre `margenes_de_compra` (ya prevé su cambio).

## Revisión de la constitución

Cumple `CLAUDE.md`: escritura solo por RPC `security definer` con `set search_path = ''`; autorización con `private.rol_actual()`; RLS en `parametros_historial` (solo Administrador) y sin privilegios de escritura para la API; auditoría con `private.auditar`; evento con `private.carga_evento` (clave, versión; nunca valores); no se mueve dinero (no toca el libro); migraciones solo hacia adelante.

## Decisiones de diseño (de detalle, no escritas en docs)

- **Tipos y rangos** salen de la tabla de `docs/02` §10: `numero` con `minimo`/`maximo` (nulo = sin tope; "≥ 0" es mínimo 0), `lista` (jsonb arreglo), `texto`. Un valor de otro tipo JSON que el declarado responde `PARAMETRO_FUERA_DE_RANGO` (`docs/06` §9 no define otro código).
- **Enumerados** (`ia.horizonte.*`: intradía, días, semanas): la tabla no tiene dónde guardar la lista permitida; la valida la función con la lista de `docs/02` §10. La lista de modelos (`ia.modelo_*`) la valida HU-054 (CB-79): aquí son `texto` sin más validación.
- **`cupos.maximo_usd` "sin límite"**: se guarda como `null` JSON; el cambio acepta número ≥ 0 o `null`.
- **Parámetros de `auth.*`**: se siembran ya (HU-002); aquí solo se valida que sean arreglos de textos al cambiarlos. `app.minutos_bloqueo` es nuevo.
- **`reparto`**: `valor` es un objeto `{"pct_reserva":…, "pct_arriesgadas":…, "pct_usuarios":…}`; exactamente esas tres claves, cada una 0–100, suma 100. Llamar con `reparto.pct_*` suelto responde `PARAMETRO_FUERA_DE_RANGO` (CB-78, `docs/06` §6). Deja una fila de historial por clave y una sola entrada de bitácora (`entidad_id = 'reparto'`).
- **Motivo obligatorio** (CA-1 "con un motivo"): un motivo vacío falla con `22023` y mensaje claro, sin inventar un código de `docs/06` §9; una clave que no existe responde `NO_EXISTE`.
- **Versión y evento**: cada cambio hace `version = version + 1`, `actualizado_por/en`. Evento `parametro` en `admin` con `carga_evento('parametros', clave, version, 'cambiado')`; para `reparto`, uno por cada clave.
- **Historial**: `parametros_historial` se llena solo desde la RPC; sin escritura para la API; lectura solo Administrador (`docs/03` §4.3).
- **Sin comparaciones cruzadas** (p. ej. stop_min ≤ stop_max): `docs/` no las pide.

## Estructura

```text
supabase/migrations/<fecha>_catalogo_de_parametros.sql   # catálogo + parametros_historial + RLS
supabase/migrations/<fecha>_actualizar_parametro.sql     # private.validar_parametro + RPC
supabase/migrations/<fecha>_margenes_desde_parametros.sql
supabase/tests/database/10_politicas_*_test.sql
docs/17-mapa-de-modulos.md
```
