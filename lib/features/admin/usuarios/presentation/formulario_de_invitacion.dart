/// Formulario para invitar a una persona: correo de Google, rol y, solo para
/// Usuario, cupo inicial (HU-003, PM-50).
///
/// La app no envía correos (docs/04 §4.1): una ayuda fija lo dice antes de invitar y,
/// al crear la invitación, el aviso de éxito repite a quién y con qué rol se invitó y
/// recuerda que el Administrador debe avisar a la persona. El cupo
/// inicial es solo una intención hasta que la persona entra (docs/02 §11, RN-18).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/formato/formato_fechas.dart';
import '../../../../core/perfil/perfil.dart';
import '../../../../shared/widgets/avisos.dart';
import '../../../../shared/widgets/botones.dart';
import '../../../../shared/widgets/campo.dart';
import '../../../../shared/widgets/lista_desplegable.dart';
import '../../../../app/tema.dart';
import '../domain/invitacion.dart';
import 'etiquetas.dart';
import 'invitaciones_provider.dart';

/// Texto del botón que crea la invitación.
const String textoInvitar = 'Invitar';

/// Forma de un correo: algo, arroba, algo, punto, algo; sin espacios. Es la misma
/// forma que exige la base de datos.
final RegExp _formaDeCorreo = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

/// Un monto en USD con hasta dos decimales, con punto o coma decimal.
final RegExp _formaDeMonto = RegExp(r'^\d+([.,]\d{1,2})?$');

class FormularioDeInvitacion extends ConsumerStatefulWidget {
  const FormularioDeInvitacion({super.key});

  static const Key claveDelCorreo = Key('invitacion-correo');
  static const Key claveDelCupo = Key('invitacion-cupo');
  static const Key claveDelAvisoDeCreada = Key('invitacion-creada');
  static const Key claveDelAvisoDeError = Key('invitacion-error');

  /// Ayuda fija del formulario: la app no envía correos (docs/04 §4.1).
  static const Key claveDeLaAyuda = Key('invitacion-ayuda');

  @override
  ConsumerState<FormularioDeInvitacion> createState() =>
      _FormularioDeInvitacionState();
}

class _FormularioDeInvitacionState
    extends ConsumerState<FormularioDeInvitacion> {
  final _correo = TextEditingController();
  final _cupo = TextEditingController();
  RolApp _rol = RolApp.usuario;
  bool _enviando = false;
  String? _errorDelCorreo;
  String? _errorDelCupo;
  Object? _error;
  Invitacion? _creada;

  /// El lugar donde salen el resultado y el error, para llevarlo a la vista.
  final _claveDelResultado = GlobalKey();

  @override
  void dispose() {
    _correo.dispose();
    _cupo.dispose();
    super.dispose();
  }

  /// Valida lo que la base también valida, para no gastar una llamada en un
  /// correo mal escrito. Devuelve el cupo si todo está bien.
  double? _validar() {
    final correo = _correo.text.trim();
    String? errorDelCorreo;
    String? errorDelCupo;
    var cupo = 0.0;

    if (!_formaDeCorreo.hasMatch(correo)) {
      errorDelCorreo = 'Escribe un correo como nombre@gmail.com.';
    }
    if (_rol == RolApp.usuario) {
      final texto = _cupo.text.trim();
      if (texto.isNotEmpty) {
        if (_formaDeMonto.hasMatch(texto)) {
          cupo = double.parse(texto.replaceAll(',', '.'));
        } else {
          errorDelCupo = 'Escribe un monto en USD, como 250 o 250,50.';
        }
      }
    }

    setState(() {
      _errorDelCorreo = errorDelCorreo;
      _errorDelCupo = errorDelCupo;
    });
    return errorDelCorreo == null && errorDelCupo == null ? cupo : null;
  }

  Future<void> _enviar() async {
    final cupo = _validar();
    if (cupo == null) return;

    setState(() {
      _enviando = true;
      _error = null;
      _creada = null;
    });
    try {
      final invitacion = await ref
          .read(invitacionesProvider.notifier)
          .invitar(
            email: _correo.text.trim(),
            rol: _rol,
            cupoInicial: _rol == RolApp.usuario ? cupo : 0,
          );
      if (!mounted) return;
      _correo.clear();
      _cupo.clear();
      setState(() => _creada = invitacion);
      _llevarElResultadoALaVista();
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = error);
      _llevarElResultadoALaVista();
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  /// En el teléfono el resultado queda debajo del botón y, con el teclado abierto o
  /// la pantalla corta, fuera de la vista: se baja hasta él para que se lea.
  void _llevarElResultadoALaVista() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final contexto = _claveDelResultado.currentContext;
      if (!mounted || contexto == null) return;
      Scrollable.ensureVisible(
        contexto,
        duration: Duration.zero,
        alignmentPolicy: ScrollPositionAlignmentPolicy.keepVisibleAtEnd,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Semantics(
          header: true,
          child: Text('Invitar a una persona', style: textos.titleLarge),
        ),
        const SizedBox(height: Espacio.x3),
        const AvisoEnLinea(
          key: FormularioDeInvitacion.claveDeLaAyuda,
          tipo: TipoAviso.informacion,
          mensaje:
              'La app no envía correos. Después de invitar, avisa a la persona '
              'que entre con Google con ese Gmail. En modo de prueba, su Gmail '
              'también debe estar en los usuarios de prueba de Google.',
        ),
        const SizedBox(height: Espacio.x4),
        Campo(
          key: FormularioDeInvitacion.claveDelCorreo,
          etiqueta: 'Correo de Google',
          controlador: _correo,
          teclado: TextInputType.emailAddress,
          pista: 'nombre@gmail.com',
          ayuda: 'La persona entra con esa cuenta de Google.',
          error: _errorDelCorreo,
          alCambiar: (_) {
            // Empezar otra invitación quita el aviso de la anterior.
            if (_errorDelCorreo != null || _creada != null) {
              setState(() {
                _errorDelCorreo = null;
                _creada = null;
              });
            }
          },
        ),
        const SizedBox(height: Espacio.x4),
        ListaDesplegable<RolApp>(
          etiqueta: 'Rol',
          opciones: [
            for (final rol in RolApp.values)
              OpcionExcluyente(valor: rol, etiqueta: etiquetaDeRol(rol)),
          ],
          valor: _rol,
          alElegir: _enviando ? null : (rol) => setState(() => _rol = rol),
        ),
        if (_rol == RolApp.usuario) ...[
          const SizedBox(height: Espacio.x4),
          Campo(
            key: FormularioDeInvitacion.claveDelCupo,
            etiqueta: 'Cupo inicial (USD)',
            controlador: _cupo,
            teclado: const TextInputType.numberWithOptions(decimal: true),
            pista: '0,00',
            ayuda:
                'Se asigna cuando la persona entra, si la bolsa común lo '
                'cubre. Vacío es 0.',
            error: _errorDelCupo,
            alCambiar: (_) {
              if (_errorDelCupo != null) setState(() => _errorDelCupo = null);
            },
          ),
        ],
        const SizedBox(height: Espacio.x5),
        Align(
          alignment: Alignment.centerLeft,
          child: BotonPrimario(
            texto: textoInvitar,
            icono: Icons.person_add_alt,
            enviando: _enviando,
            alPresionar: _enviar,
          ),
        ),
        Column(
          key: _claveDelResultado,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_error != null) ...[
              const SizedBox(height: Espacio.x4),
              AvisoEnLinea.deError(
                _error,
                key: FormularioDeInvitacion.claveDelAvisoDeError,
              ),
            ],
            if (_creada != null) ...[
              const SizedBox(height: Espacio.x4),
              AvisoEnLinea(
                key: FormularioDeInvitacion.claveDelAvisoDeCreada,
                tipo: TipoAviso.exito,
                titulo: 'Invitación creada',
                mensaje:
                    'Invitación creada para ${_creada!.email} como '
                    '${etiquetaDeRol(_creada!.rol)}. La app no envía correos: '
                    'avísale que entre con Google con ese Gmail antes del '
                    '${formatearFechaHora(_creada!.expiraEn)}.',
              ),
            ],
          ],
        ),
      ],
    );
  }
}
