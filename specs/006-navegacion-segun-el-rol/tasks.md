---
description: "Tareas de HU-006 · Navegación y guardas según el rol"
---

# Tareas: HU-006 · Navegación y guardas según el rol

**Entrada**: [plan.md](plan.md), [spec.md](spec.md), [data-model.md](data-model.md), [contracts/interfaces-de-la-app.md](contracts/interfaces-de-la-app.md), [research.md](research.md).

Una sola historia de usuario (US1). Cada fase es una capa con sus pruebas y termina en un commit. Solo app y E2E: sin migraciones. La cuenta de prueba suspendida (T015) está **condicionada** a la respuesta del coordinador.

## Fase 1 · Política y registro (commit 1)

- [x] T001 [P] [US1] `lib/app/acceso_por_rol.dart`: `AccesoDeRuta { permitido, soloLectura, denegado }`, `accesoDeRuta(RolApp? rol, String ruta)` con la tabla "Política" de `data-model.md` (`/admin` y `/admin/*` solo Administrador; `/cupo` solo Usuario; `/riesgo` y `/riesgo/*` Analista `permitido`, Administrador `soloLectura`, Usuario `denegado`; `/inicio` `permitido` para cualquier rol, también `null`; rol desconocido `denegado` en el resto; coincidencia por segmento, así `/administracion` no cuenta como `/admin`) y `redirigirSegunAcceso({ruta, haySesion, claims})` con la tabla "Decisión de la guarda" (catálogo sin guarda; sin sesión → `/ingreso`; `app_estado` distinto de `activo` o sin claim → `/cuenta-suspendida`; `/ingreso` y `/cuenta-suspendida` con sesión activa → `/inicio`; denegado → `/inicio`); `test/app/acceso_por_rol_test.dart` con cada rol por cada ruta y cada caso de la guarda (CA-2, CA-3, CA-4)
- [x] T002 [P] [US1] `lib/app/destinos.dart`: `Destino {ruta, etiqueta, icono, roles, pantalla}`, `destinosDelMvp` (Mercado `/inicio`, Oportunidades `/oportunidades`, Mi cupo `/cupo`, Alertas `/alertas`, Administración `/admin`, con los roles de `data-model.md`) y `destinosDeRol(RolApp?)` en ese orden; `test/app/destinos_test.dart`: Usuario = Mercado, Oportunidades, Mi cupo, Alertas; Analista = Mercado, Oportunidades, Alertas; Administrador = Mercado, Oportunidades, Alertas, Administración; ninguno pasa de cuatro; Nueva orden manual y las pantallas fuera del MVP corto no aparecen (CA-1); cada destino coincide con `accesoDeRuta` (el registro y la política no se contradicen)

## Fase 2 · Sesión y piezas pequeñas (commit 2)

- [x] T003 [US1] `lib/features/auth/presentation/acceso_de_sesion_provider.dart`: `AccesoDeSesion {haySesion, claims, rol, estado}`, `accesoDeSesionProvider` sobre `sesionProvider` y `ClaimsDeSesion.desdeToken(session.accessToken)`, y `accesoDeRutaProvider` (`Provider.family<AccesoDeRuta, String>`); `test/features/auth/presentation/acceso_de_sesion_provider_test.dart` con tokens por rol, suspendido y sin claims (usa `sesionDePrueba` de `test/features/auth/falsos.dart`, ampliado para aceptar claims)
- [x] T004 [P] [US1] `lib/features/auth/data/ingreso_repositorio.dart`: `cerrarSesion()` (`signOut` de Supabase y `cerrarSesionDeGoogle()`), con `ClienteDeAuth.cerrarSesion()`; ampliar `test/features/auth/data/ingreso_repositorio_test.dart` y `test/features/auth/falsos.dart`
- [x] T005 [P] [US1] `lib/shared/widgets/barra_de_pestanas.dart`: `Pestana.clave` (opcional) usada como `Key` del destino; ampliar `test/shared/widgets/` de la isla si existe (o `franja_y_barras_test.dart`)

## Fase 3 · Forma de las pantallas (commit 3)

- [x] T006 [US1] `/impeccable shape` del cascarón de navegación (isla y riel), del marcador de sección y de la pantalla de cuenta suspendida, a partir de la historia y de `DESIGN.md`; el brief queda en `specs/006-navegacion-segun-el-rol/forma-de-las-pantallas.md` (textos que no están en `docs/` incluidos)

## Fase 4 · Pantallas (commit 4)

- [x] T007 [P] [US1] `lib/app/pagina_marcador.dart`: marcador de una sección del MVP corto que aún no existe (`EstadoVacio` con el nombre de la sección, texto de T006), con `BarraSuperior`; `test/app/pagina_marcador_test.dart` (claro y oscuro, texto al doble)
- [x] T008 [P] [US1] `lib/features/auth/presentation/pagina_cuenta_suspendida.dart`: barra grafito, hoja con "Tu cuenta está suspendida. Comunícate con el administrador." (`docs/04` §11) y botón "Cerrar sesión" que llama a `cerrarSesion()` del repositorio; `test/features/auth/presentation/pagina_cuenta_suspendida_test.dart` (texto exacto, botón, claro y oscuro, texto al doble, sin desbordes)
- [x] T009 [US1] `lib/app/cascaron_de_navegacion.dart`: `CascaronDeNavegacion` con la isla (`BarraDePestanas`) por debajo de 840 dp y `NavigationRail` desde 840 dp, con los destinos de `destinosDeRol(rol)` y la pestaña actual según la ruta (prefijo: `/admin/usuarios` marca Administración); claves por destino; `test/app/cascaron_de_navegacion_test.dart`: menú de Usuario, de Analista y de Administrador en teléfono y en ventana ancha, destino actual, tocar un destino navega, claro y oscuro (CA-1)

## Fase 5 · Enrutador (commit 5)

- [x] T010 [US1] `lib/app/enrutador.dart`: `ShellRoute` con el cascarón y las rutas de `destinos.dart` (`/inicio` con `PaginaInicio`, `/oportunidades`, `/cupo`, `/alertas` y `/admin` con `PaginaMarcador`, y sus subrutas por prefijo), `/cuenta-suspendida` fuera del cascarón, `redirect` con `redirigirSegunAcceso` y los claims de `accesoDeSesionProvider`, `refrescarCon` ligado al cambio de sesión y `onException` → `/inicio`; sin ruta de `/riesgo`
- [x] T011 [US1] `test/app/enrutador_test.dart` (ampliar) y `test/app/aplicacion_test.dart` (adaptar sin quitar comprobaciones): sin sesión → `/ingreso`; token suspendido o sin claims → `/cuenta-suspendida` y de ahí no sale a otra ruta; Usuario en `/admin` y `/admin/usuarios` → `/inicio`; Analista en `/admin` → `/inicio`; Analista y Administrador en `/cupo` → `/inicio`; cualquiera en `/riesgo/...` o en una ruta inexistente → `/inicio`; Administrador en `/admin` entra; el cambio de rol del token reconstruye el menú; reactivar (estado activo) saca de `/cuenta-suspendida`; el catálogo sigue sin guarda (CA-1 a CA-4)

## Fase 6 · E2E-01 (commit 6)

- [x] T012 [P] [US1] `supabase/tests/e2e/01_ingreso_por_rol_test.ts`: iniciar sesión con `admin@prueba.local`, `analista1@prueba.local` y `usuario1@prueba.local` y comprobar `app_rol` y `app_estado`; la RLS de `perfiles` por rol (el Usuario ve solo su fila; el Analista y el Administrador, todas); una cuenta creada con el arnés (`crearUsuarioDePrueba`) y suspendida dentro de la prueba trae `app_estado = suspendido` en su siguiente token; todo lo que cree se borra en un `finally` (docs/15 §4, E2E-01)
- [x] T013 [US1] `integration_test/app_test.dart`: E2E-01 de la app: abrir en `/ingreso`, entrar con cada usuario de la semilla por correo, comprobar su menú por las claves de los destinos, abrir `/admin` (y `/riesgo`) como Usuario y Analista y volver al inicio, y que el Administrador entra a Administración; entre roles `Supabase.instance.client.auth.signOut()` desde la prueba (cerrar sesión desde la interfaz es de HU-007); conserva el escenario de entrada de HU-005

## Fase 7 · Cuenta de prueba suspendida (condicionada)

- [ ] T014 [US1] **Solo si el coordinador aprueba la precisión de `docs/15` §3**: `supabase/seed.sql` con `suspendido@prueba.local` (perfil `suspendido`, invitación aceptada, sin bloqueo en Auth, misma contraseña de la semilla), `docs/15` §3 (fila "Usuarios de prueba") y el historial de `docs/13` §4; ajustar las pruebas pgTAP que cuentan perfiles de la semilla; agregar al E2E de la app el escenario "la cuenta suspendida entra y llega a `/cuenta-suspendida`, sin poder abrir otra ruta" (CA-3). Sin aprobación, no se hace y el informe lo dice

## Fase 8 · Cierre (commit 7)

- [ ] T015 [US1] `/impeccable audit` y `/impeccable polish` de las pantallas revisándolas en Chrome (y en el emulador de Android si la memoria lo permite): menú de los tres roles, teléfono y ventana ancha, claro y oscuro, escala de texto grande; lo hallado se corrige aquí
- [x] T016 [P] `DESIGN.md` (cascarón, marcador, cuenta suspendida), `lib/app/catalogo/pagina_componentes.dart` si se agrega un componente de sistema, y `docs/17` (M-01: rutas, `destinos.dart`, `acceso_por_rol.dart`, pruebas, E2E-01); sin tocar las secciones de reglas de `docs/` (salvo T014 si se aprobó)
- [ ] T017 Tras `git fetch origin && git rebase origin/main` (conservar las dos cosas si HU-003 tocó el enrutador), `scripts/verificar.sh` completo en verde con el candado de Supabase local
- [ ] T018 Cuerpo del PR (`.github/pull_request_template.md`, "Closes #23", título "HU-006 · Navegación y guardas según el rol") en `C:\Users\Javier\Desktop\Nastock.md\pr-006-navegacion-segun-el-rol.md` y relevo en `relevos\006-navegacion-segun-el-rol.md`

## Dependencias

T001 y T002 primero; T003 usa T001. T009 usa T002, T003 y T005. T007 y T008 usan T006 (forma) y T004. T010 usa T001 a T009. T011 sigue a T010. T012 es independiente de la app; T013 sigue a T010 y a T005. T014 sigue a T013 y a la respuesta del coordinador. T015 sigue a T010. T017 sigue a todas.

Paralelizables: T001 con T002; T004 y T005 con T003; T007 con T008; T012 con las fases de la app.

## Estrategia

Todo es parte de US1. Primero lo que no depende de nada (política y registro), luego la forma (T006) antes de construir las pantallas (T007 a T009), después el enrutador (T010, T011) y al final el E2E-01 y el cierre. Cada commit deja la app compilando y las pruebas en verde.
