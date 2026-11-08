# Guía de validación: HU-006 · Navegación y guardas según el rol

Detalles de interfaz en [contracts/interfaces-de-la-app.md](contracts/interfaces-de-la-app.md); política y decisión de la guarda en [data-model.md](data-model.md).

## 1. Automático

Con el candado de Supabase local tomado (ver el relevo):

```bash
scripts/verificar.sh --rapido     # analiza y prueba app y backend; para iterar
scripts/verificar.sh              # completo, con el E2E-01 de la app en Chrome (obligatorio al terminar)
```

Esperado:

- Pruebas unitarias de la política (`accesoDeRuta` para cada rol y cada ruta) y de la decisión de la guarda (cada caso de la tabla de [data-model.md](data-model.md)).
- Pruebas de widget del cascarón para cada rol (menú de **Usuario**, **Analista** y **Administrador**, en teléfono y en ventana ancha), de la pantalla de cuenta suspendida y de los marcadores.
- Pruebas del enrutador: sin sesión → `/ingreso`; token suspendido → `/cuenta-suspendida`; Usuario en `/admin/...` o `/riesgo/...` → `/inicio`; ruta inexistente → `/inicio`; el cambio de rol del token reconstruye el menú.
- **E2E-01 de backend** (`supabase/tests/e2e/01_ingreso_por_rol_test.ts`): claims por rol y de una cuenta suspendida creada en la prueba; RLS de `perfiles` por rol.
- **E2E-01 de la app** (`integration_test/app_test.dart`): cada rol ve su menú y las rutas prohibidas vuelven al inicio.

## 2. A mano (opcional)

`flutter run -d chrome --dart-define=MODO_PRUEBAS=true --dart-define=SUPABASE_URL=http://127.0.0.1:54321 --dart-define=SUPABASE_PUBLISHABLE_KEY=…` con el Supabase local en marcha. Ingresar con `admin@prueba.local`, `analista1@prueba.local` y `usuario1@prueba.local` (contraseña de la semilla). Esperado: el Administrador ve Mercado, Oportunidades, Alertas y Administración; el Analista, las tres primeras; el Usuario, Mercado, Oportunidades, Mi cupo y Alertas. Cambiar el ancho de la ventana por encima de 840 dp cambia la isla por el riel con los mismos destinos. Escribir `#/admin` siendo Usuario o Analista vuelve a `#/inicio`.
