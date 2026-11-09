# Plan de implementación: HU-013 · Libro contable de doble partida

**Rama**: `013-libro-contable` · **Spec**: [spec.md](spec.md) · **Módulo**: M-03 (`docs/17` §M-03)

## Resumen

Un solo cambio de base de datos: cuatro tablas (`fondos`, `subcuentas`, `movimientos`, `asientos`), la única escritura del libro (`private.registrar_movimiento`), sus dos defensas (verificación diferida de suma cero e inmutabilidad), RLS de lectura, los datos iniciales y la verificación diaria. Sin Edge Functions ni app.

## Contexto técnico

PostgreSQL 17 (Supabase). Pruebas pgTAP. Fuentes: `docs/06` §3, §4, §7, §8.2; `docs/03` §4.3; `docs/02` RN-01, RN-04 a RN-06; `docs/05` §7.

## Por capas

1. **Tablas y RLS** (`20261109120000`): enums (el tipo `bolsillo` ya lo creó la lista blanca), tablas con sus `CHECK` (RN-05) e índices únicos (un fondo; una subcuenta por tipo fijo; un cupo abierto por persona), sin privilegios de escritura, políticas de lectura (Usuario: su cupo; supervisores: todo; `fondos` solo supervisores).
2. **Escritura y defensas** (`20261109120002`): `private.registrar_movimiento(tipo, asientos, referencia, descripcion, parametros, creado_por)`; *constraint triggers* diferidos de suma cero (L1); triggers por sentencia que rechazan `UPDATE`/`DELETE`/`TRUNCATE` (L3).
3. **Datos iniciales** (`20261109120004`): el fondo y las cinco subcuentas fijas en 0, interruptores apagados (CA-1).
4. **Verificación diaria** (`20261109120006`): `private.verificar_libro()` y el trabajo `verificar_libro` (07:00 UTC).

## Diseño pensando en lo que viene

- Subcuenta de cupo: `tipo = 'cupo'` con `usuario_id`; HU-017 la crea con `private.crear_cupo()` sin tocar el esquema. Un cupo cerrado y uno abierto por persona caben (índice parcial).
- Los movimientos de aporte (HU-014/015), asignación y reducción (HU-018) y `mi_cupo()` (HU-019) solo llaman a `registrar_movimiento` y leen `subcuentas`.
- `referencia` y `parametros` guardan el vínculo con `movimientos_capital` y los porcentajes del reparto (RN-08).

## Decisiones que no están en `docs/` y se tomaron aquí

- `fondos` se lee solo por analista y administrador: la matriz de `docs/03` §4.3 no la lista.
- El nombre del fondo es «Fondo RiTech».
- `registrar_movimiento` recibe `referencia` como JSON y un sexto parámetro opcional `creado_por`; se documentó en `docs/06` §8.2.
- La alerta de la verificación diaria queda pendiente de HU-085 (no existe la tabla `alertas`): hoy la función devuelve las diferencias y emite un aviso en el registro.

## Pruebas

`supabase/tests/database/12_libro_contable_test.sql` (68 pruebas): estructura, CA-1 a CA-5, L1 a L5, RN-05, inmutabilidad (dueño, `service_role`), lectura por rol y cuenta suspendida.
