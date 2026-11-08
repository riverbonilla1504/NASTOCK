# Investigación: HU-006 · Navegación y guardas según el rol

Sin "NEEDS CLARIFICATION" abiertos, salvo D-9 del plan (cuenta de prueba suspendida), que espera la respuesta del coordinador y tiene alternativa.

## R-1 · De dónde sale el rol y el estado

- **Decisión**: del token de la sesión, con `ClaimsDeSesion.desdeToken(session.accessToken)` (HU-001). El claim `app_rol` y el `app_estado` los agrega el hook "token personalizado" (`docs/04` §7).
- **Razón**: es síncrono (el enrutador decide en el primer fotograma) y `docs/03` §4.1 manda que la app arme su navegación con el token. `perfilProvider` pide además la fila de `perfiles` por red: no sirve para decidir una ruta.
- **Límite que se acepta**: el token puede tardar hasta 15 minutos en reflejar un cambio de rol o de estado (`docs/04` §8); la seguridad real no depende de esto (RLS y RPC). Forzar la renovación al cambiar el rol es de HU-011/HU-084.
- **Un token sin claims** (hook sin registrar, o persona sin perfil) → estado nulo → no activo → `/cuenta-suspendida`. Es la opción segura: no muestra datos ni un menú de un rol inventado.

## R-2 · Cómo se redirige en `go_router` 18

- **Decisión**: `redirect` global (ya existe por HU-005) con la función pura `redirigirSegunAcceso`, `refreshListenable` conectado al cambio de sesión (el token renovado puede traer otro rol) y `onException` para las rutas que no existen.
- **Razón**: `onException(BuildContext, GoRouterState, GoRouter)` existe desde `go_router` 12; llevar a `/inicio` ahí cumple "el enrutador devuelve al inicio a quien llegue por un enlace" sin crear rutas de pantallas que no existen.
- **Alternativas**: `errorBuilder` con una página que redirige (parpadea una pantalla); una ruta comodín (go_router no tiene comodín de ruta como tal).

## R-3 · Menú: isla o riel

- **Decisión**: `ShellRoute` con un cascarón que elige según el ancho: isla (`BarraDePestanas`) por debajo de 840 dp y `NavigationRail` desde 840 dp (la clase "expandida" de Material 3). Mismos destinos y mismo orden.
- **Razón**: `DESIGN.md` dice "En ventanas anchas se usa el riel de navegación con los mismos roles, sin la isla" y no fija el umbral; `tema.dart` ya trae `navigationRailTheme`. La isla está diseñada para cuatro destinos (la píldora actual más tres íconos en 360 dp): el máximo del MVP corto es cuatro (Administrador).
- **Nueva orden manual** no entra como pestaña: la isla no admite un quinto destino y la acción va en la tarjeta de detalle de un símbolo (regla de la columna de cifras libre). La ruta y la regla de acceso (solo Usuario) las crea HU-075.

## R-4 · Modo de solo lectura del Administrador (CA-4)

- **Decisión**: `AccesoDeRuta.soloLectura` para el Administrador bajo `/riesgo`, expuesto por `accesoDeRutaProvider(ruta)`. No se crea la ruta `/riesgo`.
- **Razón**: la historia dice "las rutas de las pantallas que no existen no se crean" (sección "MVP corto" del backlog) y `docs/03` §3 excluye la Bandeja de riesgo del MVP corto; pero CA-4 pide el modo de solo lectura. La política y el proveedor quedan probados y la futura bandeja solo los consulta. Hoy un enlace a `/riesgo/...` lleva a `/inicio` para todos (D-6).

## R-5 · Pantalla de cuenta suspendida y cierre de sesión

- **Decisión**: pantalla fuera del cascarón con el texto de `docs/04` §11 y un botón "Cerrar sesión" que llama a `IngresoRepositorio.cerrarSesion()` (`signOut` de Supabase y `signOut` de `google_sign_in`).
- **Razón**: sin un botón de salida la persona queda atrapada: la guarda la devuelve a `/cuenta-suspendida` desde cualquier ruta. El cierre completo (canales de Realtime, token de push, menú de perfil) es de HU-007, que amplía `cerrarSesion()`.
- **Cuenta bloqueada de verdad** (`docs/04` §10): Auth la bloquea y no puede renovar el token ni volver a entrar; esa persona ve el mensaje en la pantalla de ingreso (HU-005, CA-3). La pantalla de esta historia es para quien tiene un token vigente cuyo estado ya cambió (hasta 15 minutos).

## R-6 · Cuenta de prueba suspendida para CA-3 y E2E-01

- **Opciones**: (a) sembrar `suspendido@prueba.local` en `seed.sql` (perfil suspendido, sin bloqueo en Auth); (b) crear y suspender una cuenta dentro del E2E de backend con el arnés (`crearUsuarioDePrueba` + `update public.perfiles`), y cubrir la pantalla con pruebas de widget y un token suspendido.
- **Por qué (a) necesita aprobación**: `docs/15` §3 enumera los usuarios de prueba de forma cerrada. Se preguntó al coordinador; la respuesta decide si el E2E de la app puede usar una cuenta suspendida real.
- **Por qué solo (b) no basta para el E2E de la app**: el E2E corre en Chrome y no puede abrir una conexión directa a Postgres; ninguna RPC suspende todavía (HU-010 es de R2).

## R-7 · E2E-01

- **Qué dice `docs/15` §4**: "Ingreso por rol: cada rol ve su navegación; rutas prohibidas redirigen" (App + backend, R1).
- **Backend**: iniciar sesión con los tres usuarios de la semilla, comprobar los claims y que la RLS de `perfiles` coincide con la navegación (el Usuario solo ve su fila; el Analista y el Administrador, todas); más la cuenta suspendida creada en la prueba.
- **App**: abrir en `/ingreso`, entrar por correo con cada usuario, ver su menú, abrir rutas de otro rol y comprobar que vuelve al inicio; entre roles `auth.signOut()` desde la prueba (cerrar sesión desde la interfaz es de HU-007). El E2E es de la **misma** `app_test.dart` de HU-005: se amplía, no se reemplaza.
