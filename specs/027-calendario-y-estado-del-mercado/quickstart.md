# Guía de comprobación (Quickstart): HU-027 · Calendario, reloj y estado del mercado

Antes de cualquier comando `supabase` o de `scripts/verificar.sh`, tomar el candado compartido: `mkdir C:/Users/Javier/.nastock-supabase-candado` (si existe, esperar) y soltarlo al terminar con `rmdir`.

## 1. Base de datos

```bash
supabase db reset
supabase test db        # incluye 05_calendario_y_horario_test.sql
```

Esperado: tabla `calendario_mercado` con RLS; `mercado_abierto()` y `mercado_en_ventana()` correctas con el reloj fijado en un día regular, un feriado, una media jornada y los dos cambios de horario de verano de 2026 (CA-2, CA-3, CA-4).

## 2. Funciones

```bash
deno test --allow-all --config supabase/functions/deno.json supabase/functions
```

Esperado: el adaptador de Alpaca convierte el calendario grabado (incluida la semana de Acción de Gracias y el cambio de marzo) a UTC; el simulado ofrece los cuatro modos del reloj; `calendario-mercado` guarda el calendario (CA-6), guarda `fraccionable` y `negociable` (CA-7) y desactiva el símbolo que deja de ser negociable (CA-5).

## 3. De punta a punta, contra la base local (broker simulado)

```bash
supabase functions serve --env-file supabase/functions/.env.e2e
# en otra terminal, con el secreto de seed.sql:
curl -s -X POST http://127.0.0.1:54321/functions/v1/calendario-mercado -H "x-secreto-interno: solo-local-no-es-secreto"
```

Esperado: respuesta 200 con `calendario.dias_guardados > 0`, `activos.consultados` igual al universo y `historia` como en HU-026. Luego, con el reloj fijado dentro de un día con sesión, `select private.mercado_abierto();` devuelve `true`.

El trabajo `calendario` de `pg_cron` queda visible con `select jobname, schedule from cron.job;` (`0 10 * * *`).
