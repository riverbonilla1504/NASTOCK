/// Raíz de Riverpod que se puede reiniciar entera (HU-007, CA-3).
///
/// Al cerrar sesión la app no debe conservar en pantalla datos de la sesión
/// anterior: ni la lista de Oportunidades que cargó el Administrador ni el
/// bolsillo que eligió en Mercado. En vez de enumerar los providers que guardan
/// datos (y olvidar el de la próxima historia), se descarta **todo** el
/// contenedor y se crea uno nuevo; el árbol de pantallas se monta otra vez y,
/// sin sesión, el enrutador lo lleva a `/ingreso`.
///
/// Las pruebas que montan `Aplicacion` dentro de su propio `ProviderScope` no
/// tienen esta raíz: [ReinicioDeProviders.maybeDe] devuelve `null` y el cierre
/// de sesión igual funciona (la sesión vacía lleva a `/ingreso`).
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;

/// Pide descartar todo el estado de la app y empezar de cero.
typedef ReinicioDeProviders = VoidCallback;

class RaizDeProviders extends StatefulWidget {
  const RaizDeProviders({
    required this.child,
    this.overrides = const [],
    super.key,
  });

  final Widget child;

  /// Reemplazos de providers (para las pruebas); valen también tras cada
  /// reinicio.
  final List<Override> overrides;

  /// La función que reinicia la raíz, o `null` si no hay una por encima.
  static ReinicioDeProviders? maybeDe(BuildContext context) =>
      context.getInheritedWidgetOfExactType<_AlcanceDelReinicio>()?.reiniciar;

  @override
  State<RaizDeProviders> createState() => _EstadoDeRaizDeProviders();
}

class _EstadoDeRaizDeProviders extends State<RaizDeProviders> {
  late ProviderContainer _contenedor;

  @override
  void initState() {
    super.initState();
    _contenedor = ProviderContainer(overrides: widget.overrides);
  }

  @override
  void dispose() {
    _contenedor.dispose();
    super.dispose();
  }

  void _reiniciar() {
    final anterior = _contenedor;
    setState(() {
      _contenedor = ProviderContainer(overrides: widget.overrides);
    });
    // El contenedor anterior se descarta cuando el árbol nuevo ya no lo usa.
    WidgetsBinding.instance.addPostFrameCallback((_) => anterior.dispose());
  }

  @override
  Widget build(BuildContext context) {
    return _AlcanceDelReinicio(
      reiniciar: _reiniciar,
      child: UncontrolledProviderScope(
        // La clave hace que todo el árbol de pantallas se monte de nuevo.
        key: ObjectKey(_contenedor),
        container: _contenedor,
        child: widget.child,
      ),
    );
  }
}

class _AlcanceDelReinicio extends InheritedWidget {
  const _AlcanceDelReinicio({required this.reiniciar, required super.child});

  final ReinicioDeProviders reiniciar;

  @override
  bool updateShouldNotify(_AlcanceDelReinicio anterior) => false;
}
