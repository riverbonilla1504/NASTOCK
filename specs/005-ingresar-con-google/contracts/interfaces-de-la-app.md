# Contratos de la app: HU-005 · Ingresar con Google en Android y web

La historia no expone API ni RPC. Sus contratos son las interfaces entre capas de la app, las rutas y las variables de entorno. Son firmas de referencia, no código.

## Variables de entorno (`--dart-define`, no son secretos)

| Nombre | Uso | Dónde llega |
|---|---|---|
| `GOOGLE_WEB_CLIENT_ID` | `serverClientId` del ingreso nativo en Android. En web no se usa (la redirección la hace Supabase). | `despliegue.yml` (ya lo pasa); local: lo da quien prueba a mano |
| `MODO_PRUEBAS` | Muestra el ingreso con correo y contraseña. Solo CI y local. | `verificar.sh` y `ci.yml` (ya lo pasan) |
| `SUPABASE_URL`, `SUPABASE_PUBLISHABLE_KEY` | Sin cambios | Sin cambios |

`Entorno.googleWebClientId` (cadena vacía si falta) y `Entorno.googleConfigurado`. En Android sin `GOOGLE_WEB_CLIENT_ID` el botón avisa de la configuración que falta en vez de abrir el selector.

## Rutas

| Ruta | Pantalla | Guarda |
|---|---|---|
| `/ingreso` | `PaginaDeIngreso` | Con sesión → `/inicio` |
| `/inicio` | `PaginaInicio` (HU-030 la reemplazará) | Sin sesión → `/ingreso` |
| `/catalogo…` | Catálogo de componentes (solo debug o `MODO_PRUEBAS`) | Sin guarda |

`/` redirige a `/inicio` (y de ahí, sin sesión, a `/ingreso`). Las demás guardas de `docs/05` §9.3 son de HU-006.

## Interfaces

```text
IngresoRepositorio
  Future<ResultadoDeIngreso> ingresarConGoogle()          // lanza FalloDeIngreso; nativo en Android, redirección en web
  Future<ResultadoDeIngreso> ingresarConCorreo(correo, contrasena)   // solo con MODO_PRUEBAS; lanza FalloDeIngreso
  Stream<FalloDeIngreso> get fallosDeRegreso              // errores del flujo OAuth web al volver a la app
  Future<void> cerrarSesionDeGoogle()                     // lo llama HU-007; no cierra la sesión de Supabase

ProveedorDeGoogleNativo                                   // envoltura de GoogleSignIn.instance, falsa en pruebas
  Future<void> iniciar(serverClientId)
  Future<CredencialDeGoogle> autenticar()                 // idToken + accessToken; lanza GoogleCanceladoException

sesionProvider                : StreamProvider<Session?>
ingresoControladorProvider    : NotifierProvider<IngresoControlador, EstadoDeIngreso>
  IngresoControlador.ingresarConGoogle() / ingresarConCorreo(correo, contrasena)

FalloDeIngreso implements Exception { TipoDeFalloDeIngreso tipo; String get mensaje; }
traducirError(Object?)        // FalloDeIngreso → su mensaje; el resto, como hasta ahora
```

```text
AlmacenamientoSeguroDeSesion extends LocalStorage          // clave "supabase.auth.token"
  AlmacenamientoSeguroDeSesion([FlutterSecureStorage? almacen])

confirmarAccion(BuildContext, {titulo, simbolo, monto, textoConfirmar, alConfirmar: Future<void> Function()})
  → Future<ResultadoDeConfirmacion>  // hecho | cancelado | error
DialogoDeConfirmacion { estado: EstadoDeConfirmacion, … }  // los seis estados de docs/08 §9.3
```

## Mensajes

Los de `data-model.md` ("`TipoDeFalloDeIngreso` y su texto"). Un `FalloDeIngreso` se dibuja con `AvisoEnLinea` de tipo error (borde doble, marca de cuadrado lleno, región viva), sin rojo (DESIGN.md).
