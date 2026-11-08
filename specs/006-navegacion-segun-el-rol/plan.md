# Plan de implementación: HU-006 · Navegación y guardas según el rol

**Rama**: `006-navegacion-segun-el-rol` | **Fecha**: 2026-11-08 | **Especificación**: [spec.md](spec.md)

## Resumen

Cada persona ve solo las pantallas de su rol. Es una historia **de la app**: sin migraciones, tablas ni Edge Functions (la seguridad real sigue en RLS y RPC, `docs/03` §4). Por capas, cada una con sus pruebas: (1) la política de acceso como funciones puras (`accesoDeRuta`, `redirigirSegunAcceso`) y el registro de destinos del MVP corto (`lib/app/destinos.dart`); (2) los claims del token como estado de navegación (`accesoDeSesionProvider`) y el enrutador con las guardas: sin sesión → `/ingreso`, estado distinto de activo → `/cuenta-suspendida`, ruta de otro rol o inexistente → `/inicio`; (3) la pantalla de cuenta suspendida y el marcador de las secciones que aún no existen; (4) el cascarón con la isla en teléfono y el riel en ventanas anchas; (5) E2E-01 de backend y de la app; (6) `docs/17`.

## Contexto técnico

**Lenguaje/Versión**: Dart 3.13 / Flutter 3.47. **Dependencias nuevas**: ninguna.

**Lo que ya existe (HU-005, HU-001, HU-116)**: `Rutas`, `redirigirSegunSesion` y `crearEnrutador({conCatalogo, haySesion, refrescarCon})` en `lib/app/enrutador.dart`; `sesionProvider` (`Session?`); `ClaimsDeSesion.desdeToken` con `rol` (`RolApp`) y `estado` (`EstadoCuenta`) en `lib/core/perfil/perfil.dart`; `BarraDePestanas` (la isla) con `Pestana`; `navigationRailTheme` en `lib/app/tema.dart`; `EstadoVacio`, `Tarjeta`, `BarraSuperior`, `BotonSecundario`, `AvisoEnLinea`.

**Pruebas**: `flutter test` (unitarias y de widget) y el E2E de la app en Chrome (`integration_test/app_test.dart`, con el ingreso por correo del modo pruebas) más un E2E de backend en Deno (`supabase/tests/e2e/01_ingreso_por_rol_test.ts`).

**Plataforma**: Android y web. **Restricciones**: la app solo decide qué mostrar; el token puede estar atrasado hasta 15 minutos (`docs/04` §8, `docs/03` §4.1); sin llaves; solo tokens de `lib/app/tema.dart` y componentes de `lib/shared/widgets/` (D-67).

## Revisión de la constitución

Cumple `CLAUDE.md`:

- La autorización sigue leyendo `perfiles` en la base; los claims solo arman la interfaz (invariante 5). Esta historia no escribe nada en la base.
- Sin llaves en la app; nada de `docs/` cambia en sus reglas.
- Pantallas con tokens y componentes del sistema; la entrada nueva va en `DESIGN.md` (docs/15 §12).
- **Pendiente de aprobación (regla de oro 2):** sembrar una cuenta de prueba suspendida cambia la fila "Usuarios de prueba" de `docs/15` §3, que hoy es una lista cerrada. Se preguntó al coordinador; hasta tener su respuesta no se toca `docs/` ni `seed.sql` (ver "Decisiones", D-9).

Reevaluada tras el diseño: sin violaciones.

## Alcance frente a otras historias

| Pieza | Dueño | Aquí |
|---|---|---|
| Guardas por sesión, estado y rol; `/cuenta-suspendida`; menú por rol; modo solo lectura del Administrador; E2E-01 | HU-006 | Sí |
| Pantalla de ingreso y la guarda `sin sesión → /ingreso` | HU-005 | Ya en `main` |
| Cerrar sesión completo (canales, token de push, menú de perfil) | HU-007 | No; solo el botón de la pantalla suspendida, que llama a `cerrarSesion()` del repositorio |
| Pantallas Mercado, Oportunidades, Mi cupo, Alertas, Administración | HU-030, HU-048, HU-019, HU-085, HU-097 | No: aquí van **marcadores** y cada historia cambia la línea de su destino en `destinos.dart` |
| `/admin/usuarios` | HU-003 | No; la guarda de `/admin/*` ya la cubre |
| Nueva orden manual | HU-075 | No: no es pestaña (ver D-2); su ruta y su regla (solo Usuario) las crea esa historia |
| Bandeja de riesgo (`/riesgo/*`) | historia posterior al MVP corto | No hay ruta (docs/03 §3, docs/14 §4.1); la **regla** sí queda (D-5) |
| Forzar la renovación del token al cambiar el rol (`perfil_actualizado`) | HU-011 y HU-084 | No |

## Decisiones de diseño

- **D-1 · Un registro de destinos.** `lib/app/destinos.dart` define `Destino` (ruta, etiqueta, ícono, roles que lo ven, constructor de pantalla) y la lista del MVP corto. El enrutador, el menú y las guardas leen de ahí; una historia posterior reemplaza solo el constructor de su destino.
- **D-2 · Menú según `docs/03` §3 (MVP corto).** Usuario: Mercado, Oportunidades, Mi cupo, Alertas. Analista: Mercado, Oportunidades, Alertas. Administrador: Mercado, Oportunidades, Alertas, Administración. **Nueva orden manual no es pestaña**: la isla de `DESIGN.md` admite cuatro destinos, la acción va en la tarjeta de detalle ("La regla de la columna de cifras libre") y el catálogo de HU-116 ya muestra la isla con esas cuatro pestañas del Usuario. Es una lectura de `docs/03` §3 que se anota en el informe.
- **D-3 · Marcadores.** Oportunidades, Mi cupo, Alertas y Administración aún no tienen pantalla: se montan con un marcador (`EstadoVacio`) bajo `/oportunidades`, `/cupo`, `/alertas` y `/admin`. Las rutas de las pantallas que no existen en el MVP corto (Bandeja de riesgo, Fondo, Perfil…) no se crean. Los nombres de ruta no están en `docs/`; salvo `/inicio`, `/ingreso`, `/cuenta-suspendida`, `/admin/*` y `/riesgo/*` (05 §9.3) son decisión de implementación y se anotan en `docs/17`.
- **D-4 · Guarda como función pura, sobre los claims.** `redirigirSegunAcceso(ruta, haySesion, claims)`: catálogo sin guarda; sin sesión → `/ingreso`; con sesión y `app_estado` distinto de `activo` (incluido un token sin el claim) → `/cuenta-suspendida`; con sesión activa, `/ingreso` y `/cuenta-suspendida` → `/inicio`; ruta sin acceso para el rol → `/inicio`. El estado viene del token (`ClaimsDeSesion`), que puede tardar hasta 15 minutos en reflejar un cambio: es para la interfaz, no para autorizar. Una sesión sin claims se trata como no activa y va a la pantalla de cuenta suspendida, que es la opción segura.
- **D-5 · Acceso por ruta y modo de solo lectura.** `AccesoDeRuta { permitido, soloLectura, denegado }` y `accesoDeRuta(rol, ruta)`: `/admin` y `/admin/*` solo Administrador; `/cupo` solo Usuario; `/riesgo` y `/riesgo/*` Analista permitido, **Administrador solo lectura**, Usuario denegado; el resto, todos. `accesoDeRutaProvider(ruta)` lo expone para que la futura Bandeja de riesgo deshabilite sus acciones al Administrador. CA-4 se prueba sobre la política y el proveedor, no sobre una pantalla: la Bandeja de riesgo no existe en el MVP corto, y las rutas de pantallas que no existen no se crean.
- **D-6 · Rutas que no existen → `/inicio`.** `onException` de `go_router` lleva a `/inicio` (docs/03 §3: "el enrutador lo devuelve al inicio"). `/riesgo/...` hoy cae aquí, también para el Administrador.
- **D-7 · Cascarón con la isla y el riel.** Un `ShellRoute` con `CascaronDeNavegacion`: la isla (`BarraDePestanas`) en ventanas de menos de 840 dp y el riel (`NavigationRail` con el tema del sistema) desde 840 dp, con los mismos destinos (`DESIGN.md`: "con los mismos roles"). La pestaña actual sale de la ruta (`/admin/usuarios` marca Administración). Cada destino lleva una clave para las pruebas (`Pestana.clave`).
- **D-8 · Pantalla de cuenta suspendida.** Fuera del cascarón: barra grafito, hoja con el texto de `docs/04` §11 ("Tu cuenta está suspendida. Comunícate con el administrador.") y un botón para cerrar la sesión (sin él la persona queda atrapada con una sesión que no sirve). `IngresoRepositorio.cerrarSesion()` hace `signOut` de Supabase y cierra la sesión de `google_sign_in`; HU-007 lo amplía con canales y token de push. Forma en `forma-de-las-pantallas.md` (`/impeccable shape`).
- **D-9 · Cuenta de prueba suspendida (pendiente).** CA-3 y su nota técnica piden "una cuenta de prueba ya suspendida". Si el coordinador aprueba la precisión de `docs/15` §3: `suspendido@prueba.local` en `seed.sql` (perfil suspendido, sin bloqueo en Auth: es el caso real de un token vigente cuyo estado ya cambió) y el E2E de la app la usa. Mientras no haya respuesta: pruebas de widget con un token suspendido y, en el E2E de backend, una cuenta creada y suspendida dentro de la prueba (se borra al terminar).
- **D-10 · E2E-01.** App: abrir, entrar con cada usuario de la semilla (administrador, analista, usuario), ver su menú, abrir rutas de otro rol y volver al inicio; entre roles se cierra la sesión con `auth.signOut()` desde la prueba. Backend: claims por rol y RLS de `perfiles` por rol (el Usuario solo se ve a sí mismo). Sin biometría ni ajustes de otras historias.

## Estructura del código

### Documentación de esta funcionalidad

```text
specs/006-navegacion-segun-el-rol/
├── spec.md
├── plan.md
├── research.md
├── data-model.md
├── quickstart.md
├── contracts/
│   └── interfaces-de-la-app.md
├── forma-de-las-pantallas.md   # /impeccable shape
└── tasks.md                    # /speckit-tasks
```

### Código

```text
lib/
├── app/
│   ├── acceso_por_rol.dart              # AccesoDeRuta, accesoDeRuta, redirigirSegunAcceso (puras)
│   ├── destinos.dart                    # Destino, destinos del MVP corto, destinosDeRol
│   ├── cascaron_de_navegacion.dart      # isla (teléfono) o riel (ventana ancha)
│   ├── pagina_marcador.dart             # marcador de una sección que aún no existe
│   └── enrutador.dart                   # ShellRoute, redirect por claims, onException
├── features/auth/
│   ├── data/ingreso_repositorio.dart    # + cerrarSesion()
│   └── presentation/
│       ├── acceso_de_sesion_provider.dart   # accesoDeSesionProvider (haySesion + claims), accesoDeRutaProvider
│       └── pagina_cuenta_suspendida.dart    # /cuenta-suspendida
└── shared/widgets/barra_de_pestanas.dart    # + Pestana.clave

test/
├── app/acceso_por_rol_test.dart, destinos_test.dart, cascaron_de_navegacion_test.dart, enrutador_test.dart (ampliada)
├── features/auth/presentation/acceso_de_sesion_provider_test.dart, pagina_cuenta_suspendida_test.dart
integration_test/app_test.dart                # E2E-01 de la app
supabase/tests/e2e/01_ingreso_por_rol_test.ts # E2E-01 de backend
```

**Decisión de estructura**: la de `docs/05` §9.1; el cascarón, el registro y la política viven en `lib/app/` porque son del enrutador, y lo que depende de la sesión, en `features/auth/` (M-01).

## Seguimiento de complejidad

Sin violaciones que justificar.
