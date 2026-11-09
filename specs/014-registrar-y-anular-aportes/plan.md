# Plan de implementación: HU-014 · Registrar y anular aportes

**Rama**: `014-registrar-y-anular-aportes` · **Spec**: [spec.md](spec.md) · **Módulo**: M-04 (`docs/17` §M-04)

## Resumen

Dos migraciones: la tabla `movimientos_capital` con su RLS y su evento, y las RPC `registrar_aporte` y `anular_aporte`. Sin Edge Functions ni app (la pantalla es HU-099). Un aporte registrado no toca el libro (RN-07): lo mueve su confirmación, en HU-015.

## Contexto técnico

PostgreSQL 17 (Supabase). Pruebas pgTAP. Fuentes: `docs/06` §4.3, §8.1, §9; `docs/03` §4.3 y §4.4; `docs/02` RN-07, RN-10; `docs/09` §3 y §4; `docs/11` §4.1.

## Por capas

1. **Tabla, RLS y evento** (`20261109130000`): tipo `estado_mov_capital`, tabla con `CHECK (monto > 0)` (CA-4) y coherencia estado/marcas, sin privilegios de escritura, lectura solo para supervisores, trigger que publica `capital` en el canal `admin`.
2. **RPC** (`20261109130002`): `registrar_aporte(monto, referencia, nota)` y `anular_aporte(id, motivo)`; sesión y rol, estado, escritura, auditoría (`capital.aporte_registrado`, `capital.aporte_anulado`), `security definer` con `search_path` vacío.

## Decisiones que no están en `docs/`

- El monto debe tener a lo sumo dos decimales (`numeric(14,2)` lo redondearía en silencio); se rechaza con 23514.
- La anulación exige un motivo no vacío (22023) y solo aplica a aportes: un id inexistente o de un retiro responde `NO_EXISTE`.
- El evento `capital` se publica en cada alta y cambio de estado (también la confirmación de HU-015).

## Pruebas

`supabase/tests/database/13_capital_aportes_test.sql` (55 pruebas): estructura, CA-1 a CA-5, evento sin montos, bitácora, coherencia de estados.
