/// Pantalla de cuenta suspendida (`/cuenta-suspendida`, docs/05 §9.3, CA-3).
///
/// La ve quien tiene un token vigente cuyo `app_estado` no es activo (la
/// suspensión o la baja llegaron mientras tenía la sesión, hasta 15 minutos de
/// retraso; docs/04 §10). No tiene menú: no hay a dónde ir. El único camino es
/// cerrar la sesión; sin ese botón la persona quedaría atrapada, porque la
/// guarda la devuelve aquí desde cualquier ruta.
///
/// Forma en `specs/006-navegacion-segun-el-rol/forma-de-las-pantallas.md`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../shared/widgets/barra_superior.dart';
import '../../../shared/widgets/botones.dart';
import '../../../shared/widgets/tarjeta.dart';
import '../data/ingreso_repositorio.dart';

/// Texto de `docs/04` §11 para una cuenta suspendida o de baja.
const String textoDeCuentaSuspendida =
    'Tu cuenta está suspendida. Comunícate con el administrador.';

class PaginaCuentaSuspendida extends ConsumerStatefulWidget {
  const PaginaCuentaSuspendida({super.key});

  static const Key claveDelBotonDeCierre = Key('cuenta-suspendida-cerrar');

  @override
  ConsumerState<PaginaCuentaSuspendida> createState() =>
      _EstadoDePaginaCuentaSuspendida();
}

class _EstadoDePaginaCuentaSuspendida
    extends ConsumerState<PaginaCuentaSuspendida> {
  bool _cerrando = false;

  Future<void> _cerrarSesion() async {
    setState(() => _cerrando = true);
    try {
      // Al cerrarse la sesión, el enrutador lleva a /ingreso y esta pantalla
      // desaparece.
      await ref.read(ingresoRepositorioProvider).cerrarSesion();
    } catch (_) {
      // Sin detalle técnico en pantalla: el botón vuelve y se puede reintentar.
    }
    if (mounted) setState(() => _cerrando = false);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
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
                            'Cuenta suspendida',
                            style: textos.headlineSmall,
                          ),
                        ),
                        const SizedBox(height: Espacio.x2),
                        Text(textoDeCuentaSuspendida, style: textos.bodyLarge),
                        const SizedBox(height: Espacio.x5),
                        BotonSecundario(
                          key: PaginaCuentaSuspendida.claveDelBotonDeCierre,
                          texto: 'Cerrar sesión',
                          enviando: _cerrando,
                          alPresionar: _cerrarSesion,
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
