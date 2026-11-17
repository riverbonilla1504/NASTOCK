# Plan: HU-109 · Aislamiento verificado por tabla y por función

**Rama**: `109-aislamiento-verificado` · **Issue**: #136 · **Módulos**: M-02, M-20 · **Spec**: [spec.md](spec.md)

## Resumen

Una suite pgTAP que recorre el catálogo de `public` y demuestra, por cada
tabla y por cada función que llama la app, lo que piden 03 §4, 06 §7 y 11 §9:
quién ve qué filas, que nadie escribe directo y que cada RPC rechaza al rol y
al dueño equivocados. La suite tiene un **registro** de tablas y funciones:
si aparece una tabla o una RPC nueva sin su caso, la suite falla, así cada
historia que crea una agrega su fila (14 §6). CI suma el asesor de seguridad
de Supabase (`supabase db advisors`) con falla ante advertencias (CA-4), y
E2E-05 suma el recorrido por la API: un Usuario no ve cupos ajenos ni escribe
directo (CA-5).

## Contexto técnico

- **Lenguaje**: SQL (pgTAP) y TypeScript (Deno) para el E2E de backend.
- **Base**: Postgres de Supabase local; Supabase CLI 2.122.0 (fijada).
- **Estado actual del catálogo** (al 2026-11-17): 26 tablas y la vista
  `posiciones_valoradas` en `public`; 18 funciones que ejecuta
  `authenticated`; `ping()` es la única que ejecuta `anon`.
- **Hallazgos al revisar el catálogo** (se corrigen en este PR):
  1. `posiciones_valoradas` conserva los privilegios por defecto de una vista
     nueva: `authenticated` tiene `INSERT`, `UPDATE`, `DELETE`, `TRUNCATE`,
     `REFERENCES` y `TRIGGER`. La vista no es actualizable (tiene un `join`) y
     es `security_invoker`, así que no se podía escribir, pero contradice 06
     §7.1: se revocan.
  2. El asesor de seguridad marca `extension_in_public` (WARN): `pg_net` se
     creó sin esquema y quedó registrada en `public` (sus objetos viven en
     `net`). No es reubicable (`extrelocatable = false`): se borra y se crea
     `with schema extensions`, como las demás.
  3. La matriz de 03 §4.3 no lista `fondos` (la migración ya lo dice en el
     comentario de su política: solo supervisores) ni `posiciones_valoradas`
     (06 §5 dice "según RLS"). Se precisa la matriz sin cambiar la regla.

## Revisión de la constitución

| Principio | Cumple | Cómo |
|---|---|---|
| I · `docs/` manda | Sí | La matriz de 03 §4.3, las reglas de 06 §7 y la tabla de 11 §9 son la especificación de la suite |
| II · Documentación primero | Sí | La historia entra por 3.31; la precisión de la matriz (`fondos`, `posiciones_valoradas`) y el paso del asesor en 15 §6 se registran en 13 §4 (3.32) |
| III · Sincronía | Sí | `docs/17` (M-02 y M-20), `docs/15` §6, `docs/18` y `docs/19` en este PR |
| IV · Investigación acotada | Sí | Solo el catálogo de `public`, las firmas de las RPC y sus chequeos de rol |
| V · Errores conocidos | Sí | EC-010 (search_path), EC-011 (vistas `security_invoker`) y EC-025 (lint) se vuelven pruebas del catálogo |
| VI · Siempre funcionando | Sí | `scripts/verificar.sh` completo; E2E-05 crece |
| VII · Alcance y costo | Sí | Herramientas de la CLI ya fijada; sin servicios nuevos |
| Invariantes | Sí | La migración solo revoca privilegios y reubica una extensión; no toca datos |

## Investigación (decisiones)

- **Una matriz declarativa, no una prueba a mano por tabla.** La suite
  guarda en una tabla temporal la clase de cada tabla de `public`
  (`todos`, `supervisores`, `administrador`, `nadie` o `dueño`) y cuenta las
  filas que ve cada persona con `query_to_xml` (corre con el rol que llama).
  *Alternativa descartada*: una sentencia por tabla y persona (más de cien
  casos repetidos que nadie mantendría).
- **El registro hace cumplir 14 §6.** El conjunto de tablas del catálogo
  debe ser igual al de la matriz, y el de funciones ejecutables por
  `authenticated`, igual al de la matriz de RPC. Una tabla o función nueva sin
  fila hace fallar la suite.
- **Datos propios de la prueba.** Cada tabla recibe al menos una fila de la
  prueba (dos para las que tienen dueño: una de cada Usuario), y la suite
  comprueba que la fila existe antes de contarla, para que ningún caso pase
  con la tabla vacía. Movimientos y asientos se crean con
  `private.registrar_movimiento`; posiciones, con `private.aplicar_llenado`;
  la auditoría, con `private.auditar` (respetan sus invariantes).
- **Rechazo de una RPC.** Para los roles equivocados activos se exige
  `NO_AUTORIZADO`; para una cuenta suspendida o sin perfil, `NO_AUTORIZADO`
  o `SESION_INVALIDA` (las dos son del catálogo de 06 §9 y algunas funciones
  comprueban la sesión antes que el rol). Las funciones de lectura abiertas a
  todos (`resumen_fondo`, `oportunidades`) no lanzan error: para la cuenta no
  activa se exige cero filas, y `oportunidades` le muestra al Usuario solo el
  bolsillo `usuarios`.
- **Dueño equivocado.** `cancelar_orden` recibe la orden de otro Usuario;
  `mi_cupo` y `crear_orden_manual` no reciben dueño (usan `auth.uid()`), así
  que se prueba que solo tocan el cupo propio. Las de Administrador no tienen
  dueño: su caso es el rol.
- **CA-3 demostrado dentro de la suite.** Se crea una tabla en `public` sin
  RLS dentro de la transacción y se comprueba que la consulta del catálogo
  la detecta; la transacción se deshace al terminar.
- **CA-4 con `supabase db advisors`.** Es el asesor de seguridad (splinter);
  `supabase db lint` es `plpgsql_check` y sigue igual. Se corre
  `--type security --level warn --fail-on warn`: los avisos `INFO`
  (`rls_enabled_no_policy` de `latido` y de `pruebas.*`) son intencionales
  (03 §4.3).

## Diseño

| Archivo | Qué prueba | CA |
|---|---|---|
| `supabase/migrations/20261117120000_aislamiento_verificado.sql` | Revoca la escritura sobre `posiciones_valoradas` y mueve `pg_net` a `extensions` | CA-1, CA-4 |
| `supabase/tests/database/28_aislamiento_catalogo_test.sql` | RLS en cada tabla (y CA-3 con una tabla sin RLS), ninguna política ni privilegio de escritura para `anon` y `authenticated`, `anon` sin lectura, vistas `security_invoker`, funciones `security definer` con `search_path = ''`, `anon` solo ejecuta `ping()`, registro de tablas y funciones | CA-1, CA-2, CA-3 |
| `supabase/tests/database/29_aislamiento_lectura_por_tabla_test.sql` | Matriz de 03 §4.3 por persona: dos Usuarios, Analista, Administrador, cuenta suspendida y anónimo; escritura directa en tablas de dinero rechazada | CA-1, CA-5 |
| `supabase/tests/database/30_aislamiento_por_funcion_test.sql` | Cada RPC con el rol equivocado, la cuenta suspendida y, donde aplica, el dueño equivocado | CA-2 |
| `supabase/tests/e2e/05_aislamiento_de_cupos_test.ts` | Por la API: un Usuario no lee el cupo de otro ni escribe directo en `subcuentas`, `movimientos` y `asientos` | CA-5 |
| `scripts/verificar.sh`, `.github/workflows/ci.yml` | Paso `supabase db advisors` | CA-4 |

## Estructura

```
supabase/migrations/20261117120000_aislamiento_verificado.sql
supabase/tests/database/28_aislamiento_catalogo_test.sql
supabase/tests/database/29_aislamiento_lectura_por_tabla_test.sql
supabase/tests/database/30_aislamiento_por_funcion_test.sql
supabase/tests/e2e/05_aislamiento_de_cupos_test.ts
```
