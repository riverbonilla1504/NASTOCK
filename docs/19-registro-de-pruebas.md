# 19 · Registro de pruebas

Qué se probó, cómo y con qué resultado. Corte al **2026-11-14**, sobre `main`
con D-72 (#196), con `scripts/verificar.sh`
completo, que es lo mismo que corre la CI en cada PR
([15](15-calidad-pruebas-y-ci-cd.md)).

---

## 1. Resultado de la corrida completa

| Paso de `verificar.sh` | Qué revisa | Resultado |
|---|---|---|
| Documentación | `scripts/verificar_docs.py`: enlaces e identificadores de `docs/` | ✅ consistente |
| Reglas de arquitectura | La IA no importa el broker; sin llaves en la app; sin `.env` versionado; nada en el esquema `pruebas` desde migraciones | ✅ |
| App Flutter | `dart format`, `flutter analyze`, `flutter test` (66 archivos) | ✅ 657 pruebas |
| Base de datos | `supabase db reset`, `db lint`, pgTAP (31 archivos, 1.457 aserciones) | ✅ |
| Funciones | `deno fmt`, `deno lint`, `deno test` (26 archivos) | ✅ 304 pruebas |
| E2E de backend | Funciones con proveedores simulados contra la base local | ✅ 21 escenarios |
| E2E de la app | `flutter drive` en Chrome sin ventana, contra la base local | ✅ |

La CI de GitHub corre los mismos pasos en cada PR y nada se integra a `main`
con la CI en rojo.

---

## 2. Casos representativos

Cada fila es un escenario automático: se ejecuta en cada PR.

| Escenario | Caso exitoso | Caso fallido o de borde | Dónde |
|---|---|---|---|
| E2E-01 · Ingreso por rol | Cada rol trae su rol en el token y ve su menú | Una cuenta suspendida deja de ver su perfil; las rutas de otro rol vuelven al inicio | `supabase/tests/e2e/01_ingreso_por_rol_test.ts`, `integration_test/app_test.dart` |
| E2E-02 · Alta con invitación | El invitado entra con el rol de su invitación | Sin invitación, vencida, de otro dominio o revocada: se rechaza con su mensaje; un Usuario no puede invitar | `02_alta_con_invitacion_test.ts` |
| E2E-03 · Mercado en vivo | Con el mercado abierto la ingesta publica precios | Con el mercado cerrado no consulta y el precio queda con su antigüedad | `01_mercado_en_vivo_test.ts` |
| E2E-06 · Ciclo de IA (backend) | El ciclo llega a Oportunidades con nivel, probabilidades de JEV y explicación; el Administrador lanza un ciclo manual | Con la IA apagada el ciclo se omite; el Usuario no ve Arriesgadas ni lanza ciclos | `06_ciclo_de_ia_test.ts` |
| E2E-07 · Calidad de datos | — | Una acción con menos de 60 barras se excluye con su motivo; sin QQQ el ciclo se omite | `07_calidad_de_datos_test.ts` |
| Libro contable | Cada movimiento suma cero; el reparto 50/25/25 es exacto | Un `UPDATE` directo de saldos se rechaza; una pérdida la absorbe la subcuenta | pgTAP `supabase/tests/database/` |
| Motor de políticas | Una orden que cumple las reglas pasa | Una que viola una regla de riesgo se rechaza con su código | pgTAP |
| Orden manual | Crear, enviar al broker simulado y aplicar el llenado | Reintentar con el mismo id no duplica; una cantidad fraccional, cero o vacía se rechaza (D-63) | pgTAP y Deno |
| Permisos y RLS | Cada rol lee lo suyo | El Usuario no ve cupos ajenos ni escribe tablas directo | pgTAP y E2E-01 |
| Sesión de la app | El perfil se lee una vez por cambio de sesión | Suscribirse otra vez a Auth no repite la historia (EC-039) | `test/core/perfil/cambios_de_sesion_test.dart` |

---

## 3. Verificación manual

| Qué | Cómo | Resultado |
|---|---|---|
| App en la nube | Emulador Android y web contra Supabase NasTock, con JEV real | Demostración del 2026-11-09: ingreso, mercado, Oportunidades y orden manual |
| Respaldo diario | Flujo "Mantenimiento" a mano | ✅ 2026-11-13 (ejecución 43504106440), con el artefacto del respaldo |
| Prueba real semanal | Alpaca paper, JEV: una llamada de solo lectura a cada proveedor | ✅ en la misma ejecución |

---

## 4. Limitaciones de las pruebas

- **Faltan E2E-04, E2E-05, E2E-08 y E2E-11** ([18 §3.3](18-estado-y-traspaso.md#33-escenarios-e2e-que-faltan)).
- **E2E-06** cubre solo el backend; la pantalla Oportunidades se prueba con
  pruebas de widget (D-72).
- Las pruebas automáticas usan **proveedores simulados**: JEV, Alpaca y el
  mercado reales solo se prueban en la nube y en la prueba real semanal.
- Errores que costó resolver y su prevención: [errores conocidos](errores-conocidos.md)
  (EC-001 a EC-040).
