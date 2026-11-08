# Contratos de la app: HU-006 · Navegación y guardas según el rol

La historia no expone API ni RPC. Sus contratos son las interfaces entre capas, las rutas y lo que las historias posteriores tocan. Son firmas de referencia, no código.

## Rutas

| Ruta | Pantalla | Quién entra |
|---|---|---|
| `/ingreso` | `PaginaDeIngreso` (HU-005) | Sin sesión (con sesión activa va a `/inicio`) |
| `/cuenta-suspendida` | `PaginaCuentaSuspendida` | Con sesión y `app_estado` distinto de activo |
| `/inicio` | `PaginaInicio` (Mercado, HU-030) | Los tres roles |
| `/oportunidades` | marcador (HU-048) | Los tres roles |
| `/cupo` | marcador (HU-019) | Usuario |
| `/alertas` | marcador (HU-085) | Los tres roles |
| `/admin` y `/admin/*` | marcador (HU-097, HU-003) | Administrador |
| `/riesgo/*` | **sin ruta** en el MVP corto | Política: Analista permitido, Administrador solo lectura |
| `/catalogo…` | Catálogo de componentes (solo debug o `MODO_PRUEBAS`) | Sin guarda |
| cualquier otra | — | `onException` → `/inicio` |

## Interfaces

```text
lib/app/acceso_por_rol.dart
  enum AccesoDeRuta { permitido, soloLectura, denegado }
  AccesoDeRuta accesoDeRuta(RolApp? rol, String ruta)
  String? redirigirSegunAcceso({required String ruta, required bool haySesion, required ClaimsDeSesion claims})
      // nulo = se queda donde está

lib/app/destinos.dart
  class Destino { String ruta; String etiqueta; IconData icono; Set<RolApp> roles; WidgetBuilder pantalla; }
  const List<Destino> destinosDelMvp
  List<Destino> destinosDeRol(RolApp? rol)         // el menú de cada rol, en orden

lib/features/auth/presentation/acceso_de_sesion_provider.dart
  class AccesoDeSesion { bool haySesion; ClaimsDeSesion claims; RolApp? get rol; EstadoCuenta? get estado }
  accesoDeSesionProvider : Provider<AccesoDeSesion>            // sobre sesionProvider
  accesoDeRutaProvider   : Provider.family<AccesoDeRuta, String>

lib/features/auth/data/ingreso_repositorio.dart
  Future<void> cerrarSesion()                      // signOut de Supabase + cerrarSesionDeGoogle()

lib/shared/widgets/barra_de_pestanas.dart
  Pestana({etiqueta, icono, iconoActivo, clave})   // clave para localizar el destino en las pruebas
```

## Lo que cambia cada historia posterior (nada más)

- **HU-030, HU-048, HU-019, HU-085, HU-097**: reemplaza el constructor `pantalla` de su `Destino` en `destinos.dart` (y agrega sus subrutas bajo la misma ruta base).
- **HU-003**: agrega `/admin/usuarios` como subruta de `/admin`; la guarda ya la cubre.
- **HU-075**: agrega su ruta y su regla en `acceso_por_rol.dart` (solo Usuario).
- **Bandeja de riesgo**: crea `/riesgo/*` y usa `accesoDeRutaProvider('/riesgo')` para deshabilitar las acciones del Administrador.

## Mensajes

La pantalla de cuenta suspendida muestra el texto de `docs/04` §11: "Tu cuenta está suspendida. Comunícate con el administrador." El resto de los textos (título, botón, marcadores) no están en `docs/` y salen de `/impeccable shape`.
