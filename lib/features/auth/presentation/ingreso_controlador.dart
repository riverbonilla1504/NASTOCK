/// Estado y acciones de la pantalla de ingreso (docs/04 §4 y §11).
///
/// ```
/// inactivo ── toca "Entrar con Google" ──▶ ingresando ──▶ (el enrutador lleva a /inicio)
///     ▲                                        │
///     │                                        ├── cancelado ──▶ inactivo   (sin mensaje)
///     └──────── vuelve a tocar ◀── fallo ◀─────┘
/// ```
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/configuracion/entorno.dart';
import '../../../core/errores/fallo_de_ingreso.dart';
import '../data/clasificador_de_fallos.dart';
import '../data/ingreso_repositorio.dart';
import '../domain/resultado_de_ingreso.dart';

/// Lo que muestra la pantalla: ingresando, o el fallo del último intento.
/// Inactivo es `ingresando == false` y `fallo == null`.
class EstadoDeIngreso {
  const EstadoDeIngreso({this.ingresando = false, this.fallo});

  final bool ingresando;
  final FalloDeIngreso? fallo;
}

class IngresoControlador extends Notifier<EstadoDeIngreso> {
  @override
  EstadoDeIngreso build() {
    // El rechazo del hook en la web llega al volver de Google, por el flujo de
    // errores de Auth, no como resultado de una llamada.
    if (ref.watch(entornoProvider).supabaseConfigurado) {
      final suscripcion = ref
          .watch(ingresoRepositorioProvider)
          .fallosDeRegreso
          .listen((fallo) => state = EstadoDeIngreso(fallo: fallo));
      ref.onDispose(suscripcion.cancel);
    }
    return const EstadoDeIngreso();
  }

  Future<void> ingresarConGoogle() =>
      _ingresar((repositorio) => repositorio.ingresarConGoogle());

  /// Solo con `MODO_PRUEBAS`: la pantalla no lo ofrece de otro modo.
  Future<void> ingresarConCorreo(String correo, String contrasena) => _ingresar(
    (repositorio) => repositorio.ingresarConCorreo(correo, contrasena),
  );

  Future<void> _ingresar(
    Future<ResultadoDeIngreso> Function(IngresoRepositorio) accion,
  ) async {
    if (state.ingresando) return;
    state = const EstadoDeIngreso(ingresando: true);
    try {
      // Éxito: el enrutador ve la sesión y lleva a /inicio. Cancelado: sin
      // mensaje. Redirigido (web): la página se va a Google. En los tres casos
      // la pantalla vuelve a inactivo.
      await accion(ref.read(ingresoRepositorioProvider));
      state = const EstadoDeIngreso();
    } catch (error, pila) {
      state = EstadoDeIngreso(fallo: clasificarFalloDeIngreso(error, pila));
    }
  }
}

final ingresoControladorProvider =
    NotifierProvider<IngresoControlador, EstadoDeIngreso>(
      IngresoControlador.new,
    );
