/// Configuración de la app que llega por `--dart-define` (docs/05 §10.1).
///
/// Nada de esto es secreto: la llave es la **publicable** de Supabase. La llave
/// secreta y las de los proveedores nunca están en la app.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

class Entorno {
  const Entorno({
    required this.supabaseUrl,
    required this.supabaseLlavePublicable,
    this.googleWebClientId = '',
    this.modoPruebas = false,
  });

  /// Valores de este arranque, tomados de `--dart-define`.
  static const Entorno actual = Entorno(
    supabaseUrl: String.fromEnvironment('SUPABASE_URL'),
    supabaseLlavePublicable: String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY'),
    googleWebClientId: String.fromEnvironment('GOOGLE_WEB_CLIENT_ID'),
    modoPruebas: bool.fromEnvironment('MODO_PRUEBAS'),
  );

  /// `SUPABASE_URL`.
  final String supabaseUrl;

  /// `SUPABASE_PUBLISHABLE_KEY`.
  final String supabaseLlavePublicable;

  /// `GOOGLE_WEB_CLIENT_ID`: el ID del cliente OAuth **Web** de Google Cloud.
  /// Es el `serverClientId` del ingreso nativo en Android (docs/04 §4.4). No es
  /// un secreto: el secreto del cliente vive solo en Supabase.
  final String googleWebClientId;

  /// `MODO_PRUEBAS`: solo en CI (ingreso con correo para las pruebas E2E).
  final bool modoPruebas;

  /// Si hay con qué conectarse a Supabase.
  bool get supabaseConfigurado =>
      supabaseUrl.isNotEmpty && supabaseLlavePublicable.isNotEmpty;

  /// Si hay con qué iniciar sesión con Google en Android.
  bool get googleConfigurado => googleWebClientId.isNotEmpty;
}

/// Entorno de este arranque. Las pruebas lo reemplazan con `overrideWithValue`.
final entornoProvider = Provider<Entorno>((ref) => Entorno.actual);
