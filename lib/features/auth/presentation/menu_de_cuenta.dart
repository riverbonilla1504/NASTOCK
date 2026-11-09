/// Menú de cuenta: el botón visible en toda pantalla con menú y la hoja que
/// muestra quién tiene la sesión y deja cerrarla (HU-007, FR-023).
///
/// En teléfono es el último ítem de la barra de navegación ("Salir", con el
/// mismo ícono de cuenta); en ventanas anchas, el botón al pie del riel. No es un
/// destino con ruta: abre la hoja de cuenta y nunca queda marcado como pestaña
/// activa. Mide 48 dp y está en los tres roles. Cerrar la sesión pide confirmación y
/// termina en `/ingreso` sin datos de la sesión anterior (ver
/// `RaizDeProviders`). La pantalla de perfil (HU-008) puede crecer desde esta
/// hoja.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/raiz_de_providers.dart';
import '../../../app/tema.dart';
import '../../../core/perfil/perfil.dart';
import '../../../shared/widgets/avisos.dart';
import '../../../shared/widgets/botones.dart';
import '../../../shared/widgets/hoja_inferior.dart';
import 'acceso_de_sesion_provider.dart';
import 'cierre_de_sesion.dart';
import 'sesion_provider.dart';

/// Texto del fallo al cerrar la sesión (sin detalle técnico).
const String textoDeFalloAlCerrarSesion =
    'No pudimos cerrar tu sesión. Inténtalo de nuevo.';

/// El rótulo de cada rol en la hoja de cuenta.
String etiquetaDeRol(RolApp? rol) => switch (rol) {
  RolApp.usuario => 'Usuario',
  RolApp.analista => 'Analista',
  RolApp.administrador => 'Administrador',
  null => 'Sin rol',
};

/// Rótulo y ícono del ítem de cuenta en la barra de navegación.
const String etiquetaDelItemDeCuenta = 'Salir';
const IconData iconoDeCuenta = Icons.account_circle_outlined;

/// Abre la hoja de cuenta (correo, rol y "Cerrar sesión" con confirmación).
Future<void> abrirHojaDeCuenta(BuildContext context) =>
    mostrarHojaInferior<void>(
      context,
      constructor: (_) => const HojaDeCuenta(),
    );

/// Botón de cuenta del riel de navegación (ventanas anchas): abre la hoja con la
/// persona y "Cerrar sesión". En teléfono el mismo papel lo hace el último ítem
/// de la isla, con esta misma [clave].
class BotonDeCuenta extends StatelessWidget {
  const BotonDeCuenta({super.key});

  static const Key clave = Key('boton-de-cuenta');

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    return Semantics(
      button: true,
      label: 'Cuenta',
      excludeSemantics: true,
      child: Tooltip(
        message: 'Cuenta',
        child: Material(
          color: c.hoja,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(Radios.control),
            side: BorderSide(color: c.reglaFuerte),
          ),
          child: InkWell(
            key: clave,
            borderRadius: BorderRadius.circular(Radios.control),
            onTap: () => abrirHojaDeCuenta(context),
            child: SizedBox.square(
              dimension: Espacio.objetivoTactil,
              child: Icon(iconoDeCuenta, color: c.tinta),
            ),
          ),
        ),
      ),
    );
  }
}

/// La hoja de cuenta: correo, rol y "Cerrar sesión".
class HojaDeCuenta extends ConsumerWidget {
  const HojaDeCuenta({super.key});

  static const Key claveDelBotonDeCierre = Key('cuenta-cerrar-sesion');

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final correo = ref.watch(sesionProvider)?.user.email;
    final rol = ref.watch(accesoDeSesionProvider).rol;
    return Padding(
      padding: const EdgeInsets.fromLTRB(
        Espacio.x4,
        Espacio.x6,
        Espacio.x4,
        Espacio.x6,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Semantics(
            header: true,
            child: Text('Cuenta', style: textos.titleLarge),
          ),
          const SizedBox(height: Espacio.x3),
          if (correo != null) Text(correo, style: textos.bodyLarge),
          Text(
            etiquetaDeRol(rol),
            style: textos.bodyMedium!.copyWith(color: c.tintaSuave),
          ),
          const SizedBox(height: Espacio.x5),
          BotonSecundario(
            key: claveDelBotonDeCierre,
            texto: 'Cerrar sesión',
            alPresionar: () => _pedirCierre(context, ref, correo),
          ),
        ],
      ),
    );
  }

  Future<void> _pedirCierre(
    BuildContext context,
    WidgetRef ref,
    String? correo,
  ) async {
    final reiniciar = RaizDeProviders.maybeDe(context);
    final cerrado = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _DialogoDeCierre(
        correo: correo,
        cerrar: () => cerrarSesionCompleta(ref),
      ),
    );
    if (cerrado != true) return;
    // La hoja ya no tiene nada que mostrar; si no hay raíz que reiniciar (las
    // pruebas), la sesión vacía basta para que el enrutador lleve a /ingreso.
    if (context.mounted) Navigator.of(context).pop();
    reiniciar?.call();
  }
}

/// La confirmación antes de cerrar la sesión.
class _DialogoDeCierre extends StatefulWidget {
  const _DialogoDeCierre({required this.correo, required this.cerrar});

  final String? correo;
  final Future<void> Function() cerrar;

  @override
  State<_DialogoDeCierre> createState() => _EstadoDelDialogoDeCierre();
}

class _EstadoDelDialogoDeCierre extends State<_DialogoDeCierre> {
  bool _cerrando = false;
  bool _fallo = false;

  Future<void> _confirmar() async {
    setState(() {
      _cerrando = true;
      _fallo = false;
    });
    try {
      await widget.cerrar();
      if (mounted) Navigator.of(context).pop(true);
    } catch (_) {
      if (mounted) {
        setState(() {
          _cerrando = false;
          _fallo = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final texto = widget.correo == null
        ? 'Tendrás que volver a ingresar.'
        : 'Vas a cerrar la sesión de ${widget.correo}. '
              'Tendrás que volver a ingresar.';
    return PopScope(
      canPop: !_cerrando,
      child: AlertDialog(
        scrollable: true,
        title: Semantics(header: true, child: const Text('¿Cerrar sesión?')),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(texto),
            if (_fallo) ...[
              const SizedBox(height: Espacio.x4),
              const AvisoEnLinea(
                tipo: TipoAviso.error,
                mensaje: textoDeFalloAlCerrarSesion,
              ),
            ],
          ],
        ),
        actions: [
          BotonTexto(
            texto: 'Cancelar',
            alPresionar: _cerrando
                ? null
                : () => Navigator.of(context).pop(false),
          ),
          BotonPrimario(
            texto: 'Cerrar sesión',
            enviando: _cerrando,
            alPresionar: _confirmar,
          ),
        ],
      ),
    );
  }
}
