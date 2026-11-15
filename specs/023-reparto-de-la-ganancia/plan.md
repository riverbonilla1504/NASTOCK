# Plan: HU-023 · Reparto de la ganancia realizada y absorción de pérdidas

**Rama**: `023-reparto-de-la-ganancia` (#192) · **Módulos**: M-04 · **Fuentes**: `docs/02` §5 · RN-23 · CB-17, CB-18, CB-19.

- **Migración** (`20261110140000_reparto_de_la_ganancia.sql`): `private.porcentajes_de_reparto` y `private.aplicar_venta` (dentro de `aplicar_llenado`, HU-074). Al vender, el cupo recibe lo cobrado, `resultados` registra la ganancia o la pérdida y, si hay ganancia, el movimiento `reparto_ganancia` la reparte 50/25/25 con los porcentajes vigentes al llenarse. Con pérdida, la subcuenta la absorbe completa y no hay reparto.
- **Redondeo** (CB-18): los centavos que no alcanzan para repartir van a la Reserva.

Decisiones sin regla explícita en `docs/`:
- Los porcentajes se guardan en el movimiento con la misma forma que el aporte.
- Sin evento, notificación ni auditoría nueva: la historia no los pide.
- La rama de Arriesgadas (CA-2) se implementó aunque en el MVP no se dispara (D-64).

Pruebas: pgTAP `21_reparto_de_la_ganancia_test.sql` (34) y el ajuste de `20_aplicar_llenado_test.sql`.
