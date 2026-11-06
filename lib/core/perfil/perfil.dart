/// Modelos del perfil de la persona que usa la app (docs/03 §4.1, docs/06 §5.1).
///
/// El rol y el estado que llegan en el token (`app_rol`, `app_estado`) son solo
/// para la interfaz: la autorización real la hace la base de datos consultando
/// `perfiles` en cada operación. Por eso la app no decide nada con ellos más
/// que qué mostrar.
library;

import 'dart:convert';

/// Rol de una persona. Un solo rol por persona (D-01, docs/03 §1).
enum RolApp {
  usuario,
  analista,
  administrador;

  /// El rol que nombra [texto] (`usuario`, `analista`, `administrador`) o
  /// `null` si es nulo o desconocido.
  static RolApp? desdeTexto(Object? texto) {
    for (final rol in values) {
      if (rol.name == texto) return rol;
    }
    return null;
  }
}

/// Estado de una cuenta (docs/06 §3). Solo una cuenta activa recibe datos.
enum EstadoCuenta {
  activo,
  suspendido,
  baja;

  /// El estado que nombra [texto] (`activo`, `suspendido`, `baja`) o `null`
  /// si es nulo o desconocido.
  static EstadoCuenta? desdeTexto(Object? texto) {
    for (final estado in values) {
      if (estado.name == texto) return estado;
    }
    return null;
  }
}

/// Fila de `perfiles` de la persona que tiene la sesión abierta.
class Perfil {
  const Perfil({
    required this.id,
    required this.email,
    required this.nombre,
    required this.rol,
    required this.estado,
    required this.recibeSugerencias,
    required this.version,
  });

  /// Columnas de `perfiles` que lee la app (sin las preferencias de push ni
  /// las marcas de tiempo, que ninguna pantalla de esta historia usa).
  static const String columnas =
      'id, email, nombre, rol, estado, recibe_sugerencias, version';

  /// Arma el perfil con una fila de `perfiles` (las [columnas] de arriba).
  ///
  /// Lanza [FormatException] si la fila no trae un rol o un estado conocidos:
  /// mejor fallar que mostrar a alguien un rol inventado.
  factory Perfil.desdeJson(Map<String, dynamic> json) {
    final rol = RolApp.desdeTexto(json['rol']);
    final estado = EstadoCuenta.desdeTexto(json['estado']);
    if (rol == null || estado == null) {
      throw const FormatException(
        'La fila de perfiles trae un rol o un estado desconocido.',
      );
    }
    return Perfil(
      id: json['id'] as String,
      email: json['email'] as String,
      nombre: json['nombre'] as String,
      rol: rol,
      estado: estado,
      recibeSugerencias: json['recibe_sugerencias'] as bool,
      version: json['version'] as int,
    );
  }

  final String id;
  final String email;
  final String nombre;
  final RolApp rol;
  final EstadoCuenta estado;

  /// PM-15.
  final bool recibeSugerencias;

  /// Sube en cada cambio de rol o de estado (docs/06 §1).
  final int version;
}

/// Los claims `app_rol` y `app_estado` del token de la sesión (docs/04 §7).
///
/// Pueden estar atrasados hasta 15 minutos respecto de `perfiles`: sirven para
/// armar la interfaz de inmediato, no para autorizar (CA-6).
class ClaimsDeSesion {
  const ClaimsDeSesion({this.rol, this.estado});

  /// Sin sesión, o un token sin los claims.
  static const ClaimsDeSesion vacios = ClaimsDeSesion();

  /// Lee los claims de un token de acceso (JWT). Un token nulo, mal formado o
  /// sin los claims da [vacios]; un valor desconocido da `null` en ese campo.
  ///
  /// No valida la firma: eso lo hace Supabase al emitir el token y la base de
  /// datos al recibirlo. Aquí solo se lee lo que el token ya dice.
  factory ClaimsDeSesion.desdeToken(String? token) {
    if (token == null) return vacios;
    final partes = token.split('.');
    if (partes.length != 3) return vacios;
    try {
      final contenido = jsonDecode(
        utf8.decode(base64Url.decode(base64Url.normalize(partes[1]))),
      );
      if (contenido is! Map<String, dynamic>) return vacios;
      return ClaimsDeSesion(
        rol: RolApp.desdeTexto(contenido['app_rol']),
        estado: EstadoCuenta.desdeTexto(contenido['app_estado']),
      );
    } on FormatException {
      return vacios;
    }
  }

  /// `app_rol`, o `null` si el token no lo trae (por ejemplo, sin perfil).
  final RolApp? rol;

  /// `app_estado`, o `null` si el token no lo trae.
  final EstadoCuenta? estado;
}

/// Lo que la app sabe de quien tiene la sesión: sus claims y su fila de
/// `perfiles`.
class PerfilDeSesion {
  const PerfilDeSesion({required this.claims, this.fila});

  /// Sin sesión: ni claims ni fila.
  static const PerfilDeSesion sinSesion = PerfilDeSesion(
    claims: ClaimsDeSesion.vacios,
  );

  /// Claims del token, solo para la interfaz. Sirven, por ejemplo, para decir
  /// por qué una cuenta no tiene acceso (`suspendido` o `baja`).
  final ClaimsDeSesion claims;

  /// Fila de `perfiles`, o `null` si la base de datos no la entregó. La base
  /// de datos solo entrega la fila de una cuenta activa (docs/03 §4.2, CA-2);
  /// con la cuenta suspendida, de baja o sin perfil no entrega ninguna.
  final Perfil? fila;

  /// Si la cuenta está activa según la base de datos, que es la fuente de
  /// verdad. No mira los claims, que pueden estar atrasados.
  bool get activo => fila != null && fila!.estado == EstadoCuenta.activo;

  /// El rol vigente: el de `perfiles` y no el del token (CA-6). `null` si la
  /// cuenta no está activa, aunque el token todavía diga otra cosa.
  RolApp? get rol => activo ? fila!.rol : null;
}
