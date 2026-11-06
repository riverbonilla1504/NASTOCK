# Guía de comprobación (Quickstart): HU-026 · Universo del NASDAQ-100 y carga histórica de barras

Cómo comprobar la historia de punta a punta en local, con el proveedor simulado. No lleva llaves.

## Requisitos

- Docker, Supabase CLI y Deno instalados (ya los usa `scripts/verificar.sh`).
- Si otra sesión usa el Supabase local, tomar el candado antes (`mkdir C:/Users/Javier/.nastock-supabase-candado`) y soltarlo al terminar.

## 1 · Base de datos (CA-1, CA-3 y CA-4)

```bash
supabase start
supabase db reset
supabase test db
```

Esperado: `04_universo_y_barras_test.sql` en verde. A mano:

```sql
select bolsillo, count(*) from public.lista_blanca group by 1 order by 1;
-- arriesgadas | 102   (TQQQ + 101 acciones)
-- usuarios    |   2   (QLD y QQQ)
select count(*), min(fecha), max(fecha) from public.barras_diarias;
-- 27040 | 2025-11-03 | 2026-10-30   (104 símbolos × 260 días)
```

## 2 · Funciones (adaptadores, simulado y lógica de la carga)

```bash
deno test --allow-all --config supabase/functions/deno.json supabase/functions
```

## 3 · La función servida contra la base real (CA-2 y CA-3)

Necesita un archivo de entorno temporal, fuera del repositorio, con las variables de `supabase/functions/.env.e2e` y `SECRETO_INTERNO=solo-local-no-es-secreto` (el valor de prueba de Vault en `seed.sql`).

```bash
supabase functions serve --env-file <archivo-temporal>
curl -s -X POST http://127.0.0.1:54321/functions/v1/calendario-mercado \
  -H "x-secreto-interno: solo-local-no-es-secreto"
```

Esperado: respuesta `200` con `simbolos_consultados: 104` y `pendientes: []`. En la base, cada símbolo queda con barras desde hace dos años hasta ayer. Repetir el `curl`: `simbolos_consultados: 0` y `barras_nuevas: 0`, y el conteo de `barras_diarias` no cambia.

Sin cabecera: `401`. Con un secreto equivocado: `403`.

## 4 · Todo junto

```bash
scripts/verificar.sh
```

Esperado: "Todo en verde".
