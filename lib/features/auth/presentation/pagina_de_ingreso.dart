/// Pantalla de ingreso (HU-005, docs/04 §4 y §11).
///
/// Forma en `specs/005-ingresar-con-google/forma-de-la-pantalla.md`: la barra
/// grafito con el nombre y una hoja blanca sobre papel con lo único que se
/// puede hacer. Sin registro ni contraseña propia: se entra con la cuenta de
/// Google con la que invitaron a la persona. El ingreso con correo existe solo
/// con `MODO_PRUEBAS` (CI y local) y ni siquiera está en el árbol sin él.
library;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../core/configuracion/entorno.dart';
import '../../../shared/widgets/avisos.dart';
import '../../../shared/widgets/barra_superior.dart';
import '../../../shared/widgets/botones.dart';
import '../../../shared/widgets/campo.dart';
import '../../../shared/widgets/tarjeta.dart';
import 'ingreso_controlador.dart';

/// Texto que ve quien desarrolla cuando falta la conexión con Supabase.
const String textoSinConexionConfigurada =
    'Falta configurar la conexión: ejecuta la app con '
    '--dart-define=SUPABASE_URL=… y '
    '--dart-define=SUPABASE_PUBLISHABLE_KEY=…';

/// Texto que ve quien desarrolla cuando falta el cliente Web de Google.
const String textoSinGoogleConfigurado =
    'Falta configurar el ingreso con Google: ejecuta la app con '
    '--dart-define=GOOGLE_WEB_CLIENT_ID=…';

class PaginaDeIngreso extends ConsumerStatefulWidget {
  const PaginaDeIngreso({super.key});

  static const Key claveDelBotonDeGoogle = Key('ingreso-boton-google');
  static const Key claveDelAvisoDeFallo = Key('ingreso-aviso-de-fallo');
  static const Key claveDelAvisoDeConfiguracion = Key(
    'ingreso-aviso-de-configuracion',
  );
  static const Key claveDelFormularioDePruebas = Key(
    'ingreso-formulario-de-pruebas',
  );
  static const Key claveDelCorreo = Key('ingreso-correo');
  static const Key claveDeLaContrasena = Key('ingreso-contrasena');
  static const Key claveDelBotonDeCorreo = Key('ingreso-boton-correo');

  @override
  ConsumerState<PaginaDeIngreso> createState() => _EstadoDePaginaDeIngreso();
}

class _EstadoDePaginaDeIngreso extends ConsumerState<PaginaDeIngreso> {
  final TextEditingController _correo = TextEditingController();
  final TextEditingController _contrasena = TextEditingController();

  /// Qué botón se tocó, para que "Procesando…" salga en ese y no en el otro.
  bool _viaCorreo = false;

  @override
  void dispose() {
    _correo.dispose();
    _contrasena.dispose();
    super.dispose();
  }

  void _ingresarConGoogle() {
    _viaCorreo = false;
    ref.read(ingresoControladorProvider.notifier).ingresarConGoogle();
  }

  void _ingresarConCorreo() {
    setState(() => _viaCorreo = true);
    ref
        .read(ingresoControladorProvider.notifier)
        .ingresarConCorreo(_correo.text, _contrasena.text);
  }

  @override
  Widget build(BuildContext context) {
    final entorno = ref.watch(entornoProvider);
    final estado = ref.watch(ingresoControladorProvider);
    final c = context.colores;
    final textos = Theme.of(context).textTheme;

    // En Android hace falta el cliente Web de Google; en web lo hace Supabase.
    final faltaGoogle = !kIsWeb && !entorno.googleConfigurado;
    final puedeIngresar = entorno.supabaseConfigurado && !faltaGoogle;

    return Scaffold(
      appBar: const BarraSuperior(titulo: 'RiTech Inversiones'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(
            Espacio.x4,
            Espacio.x8,
            Espacio.x4,
            Espacio.x6,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Tarjeta(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Semantics(
                          header: true,
                          child: Text(
                            'Entra con tu cuenta de Google',
                            style: textos.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: Espacio.x2),
                        Text(
                          'Solo pueden entrar las personas que invitó el '
                          'administrador. Usa la cuenta de Google con la que '
                          'te invitaron.',
                          style: textos.bodyMedium!.copyWith(
                            color: c.tintaSuave,
                          ),
                        ),
                        if (estado.fallo != null) ...[
                          const SizedBox(height: Espacio.x4),
                          AvisoEnLinea.deError(
                            estado.fallo,
                            key: PaginaDeIngreso.claveDelAvisoDeFallo,
                          ),
                        ],
                        if (!entorno.supabaseConfigurado || faltaGoogle) ...[
                          const SizedBox(height: Espacio.x4),
                          AvisoEnLinea(
                            key: PaginaDeIngreso.claveDelAvisoDeConfiguracion,
                            tipo: TipoAviso.advertencia,
                            mensaje: !entorno.supabaseConfigurado
                                ? textoSinConexionConfigurada
                                : textoSinGoogleConfigurado,
                          ),
                        ],
                        const SizedBox(height: Espacio.x5),
                        BotonPrimario(
                          key: PaginaDeIngreso.claveDelBotonDeGoogle,
                          texto: 'Entrar con Google',
                          enviando: estado.ingresando && !_viaCorreo,
                          alPresionar: puedeIngresar && !estado.ingresando
                              ? _ingresarConGoogle
                              : null,
                        ),
                        if (entorno.modoPruebas)
                          _FormularioDePruebas(
                            correo: _correo,
                            contrasena: _contrasena,
                            enviando: estado.ingresando && _viaCorreo,
                            alPresionar: puedeIngresar && !estado.ingresando
                                ? _ingresarConCorreo
                                : null,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: Espacio.x4),
                  Text(
                    'MVP en paper trading: una persona siempre aprueba.',
                    textAlign: TextAlign.center,
                    style: textos.bodySmall!.copyWith(color: c.tintaTenue),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Ingreso con correo y contraseña. Solo con `MODO_PRUEBAS`.
class _FormularioDePruebas extends StatelessWidget {
  const _FormularioDePruebas({
    required this.correo,
    required this.contrasena,
    required this.enviando,
    required this.alPresionar,
  });

  final TextEditingController correo;
  final TextEditingController contrasena;
  final bool enviando;
  final VoidCallback? alPresionar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Column(
      key: PaginaDeIngreso.claveDelFormularioDePruebas,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: Espacio.x6),
        Container(height: 1, color: c.regla),
        const SizedBox(height: Espacio.x4),
        Text(
          'SOLO PRUEBAS',
          style: textos.labelMedium!.copyWith(color: c.tintaSuave),
        ),
        const SizedBox(height: Espacio.x3),
        Campo(
          key: PaginaDeIngreso.claveDelCorreo,
          etiqueta: 'Correo',
          controlador: correo,
          teclado: TextInputType.emailAddress,
        ),
        const SizedBox(height: Espacio.x3),
        Campo(
          key: PaginaDeIngreso.claveDeLaContrasena,
          etiqueta: 'Contraseña',
          controlador: contrasena,
          oculto: true,
        ),
        const SizedBox(height: Espacio.x4),
        BotonSecundario(
          key: PaginaDeIngreso.claveDelBotonDeCorreo,
          texto: 'Entrar con correo',
          enviando: enviando,
          alPresionar: alPresionar,
        ),
      ],
    );
  }
}
