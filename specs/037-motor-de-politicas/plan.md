# Plan: HU-037 · Motor de políticas: reglas de la propuesta

**Rama**: `037-motor-de-politicas` (apilada sobre HU-035 y HU-034) · **Módulo**: M-08 · **Fuentes**: `docs/02` §9-§10, RN-38, `docs/06` §8.2, `docs/14` §4.1.

Migración `20261110120000_motor_de_politicas.sql`: `private.validar_operacion(subcuenta, simbolo, lado, monto, cantidad, stop_pct, confianza, momento)` devuelve `text[]` con las reglas violadas (vacía = cumple). RR-01 a RR-09, RR-11, RR-14, RR-17, RR-18, RR-21 y RR-22 con los parámetros `riesgo.*`, `mercado.*` y `jev.*`; `private.parametro_numerico` lee el catálogo. Sin tablas nuevas.

Decisiones sin regla explícita en `docs/` (a validar): `p_momento` es la hora de evaluación; RR-14 exige `trading_activo` siempre y `ia_activa` si trae confianza; RR-18 = lado inválido, cantidad no positiva o símbolo que no es acción/ETF; RR-22 = descuadre crítico sin revisar; patrimonio = efectivo + invertido y valor ya tenido en el símbolo = 0 (`private.valor_en_simbolo`) hasta que existan las posiciones.
Fuera de esta historia (HU-038): RR-10, RR-15, RR-16, RR-19, RR-20, excepciones de protecciones y liquidaciones, y las cuatro llamadas. CA-6 (texto de `REGLA_RR_xx` en la app) ya existe en `codigos_de_error.dart`.
Pruebas: `18_motor_de_politicas_test.sql` (45).
