/// Lista de invitaciones con su estado y la acción de revocar (HU-003, PM-50).
///
/// Cada fila dice el correo, el rol, el cupo inicial (solo de un Usuario), la fecha que
/// importa y el estado en un chip cuya forma de línea lo distingue sin depender del
/// color. Solo una invitación vigente ofrece "Revocar", con confirmación (D-61).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/tema.dart';
import '../../../../core/errores/traduccion_de_errores.dart';
import '../../../../core/formato/formato_dinero.dart';
import '../../../../core/formato/formato_fechas.dart';
import '../../../../core/perfil/perfil.dart';
import '../../../../shared/widgets/avisos.dart';
import '../../../../shared/widgets/botones.dart';
import '../../../../shared/widgets/chip_de_estado.dart';
import '../../../../shared/widgets/estados.dart';
import '../../../../shared/widgets/forma_de_linea.dart';
import '../../../../shared/widgets/tarjeta.dart';
import '../domain/invitacion.dart';
import 'etiquetas.dart';
import 'invitaciones_provider.dart';

class ListaDeInvitaciones extends ConsumerStatefulWidget {
  const ListaDeInvitaciones({super.key});

  static const Key claveDelVacio = Key('invitaciones-vacio');
  static const Key claveDelError = Key('invitaciones-error');

  @override
  ConsumerState<ListaDeInvitaciones> createState() =>
      _ListaDeInvitacionesState();
}

class _ListaDeInvitacionesState extends ConsumerState<ListaDeInvitaciones> {
  /// Invitaciones cuya revocación se está enviando.
  final Set<String> _revocando = {};

  Future<void> _revocar(Invitacion invitacion) async {
    final confirmada = await showDialog<bool>(
      context: context,
      builder: (_) => _DialogoDeRevocacion(email: invitacion.email),
    );
    if (confirmada != true || !mounted) return;

    setState(() => _revocando.add(invitacion.id));
    String mensaje;
    try {
      await ref.read(invitacionesProvider.notifier).revocar(invitacion.id);
      mensaje = 'Invitación revocada. ${invitacion.email} ya no puede entrar.';
    } catch (error) {
      mensaje = traducirError(error);
    }
    if (!mounted) return;
    setState(() => _revocando.remove(invitacion.id));
    mostrarAvisoTemporal(context, mensaje);
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(invitacionesProvider);
    final ahora = ref.watch(ahoraProvider)();
    final textos = Theme.of(context).textTheme;
    final lista = estado.value;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Semantics(
                header: true,
                child: Text('Invitaciones', style: textos.titleLarge),
              ),
            ),
            BotonTexto(
              texto: 'Actualizar',
              icono: Icons.refresh,
              alPresionar: estado.isLoading
                  ? null
                  : () => ref.read(invitacionesProvider.notifier).recargar(),
            ),
          ],
        ),
        const SizedBox(height: Espacio.x2),
        if (lista == null && estado.hasError)
          Padding(
            key: ListaDeInvitaciones.claveDelError,
            padding: const EdgeInsets.only(top: Espacio.x2),
            child: EstadoDeError(
              error: estado.error,
              alReintentar: () =>
                  ref.read(invitacionesProvider.notifier).recargar(),
            ),
          )
        else if (lista == null)
          const Tarjeta(child: EstadoCargando(lineas: 4))
        else ...[
          if (estado.hasError) ...[
            AvisoEnLinea.deError(
              estado.error,
              key: ListaDeInvitaciones.claveDelError,
              accion: 'Reintentar',
              alAccionar: () =>
                  ref.read(invitacionesProvider.notifier).recargar(),
            ),
            const SizedBox(height: Espacio.x3),
          ],
          if (lista.isEmpty)
            const Tarjeta(
              child: EstadoVacio(
                key: ListaDeInvitaciones.claveDelVacio,
                titulo: 'Aún no hay invitaciones',
                mensaje:
                    'Cuando invites a alguien aparecerá aquí con su estado.',
              ),
            )
          else
            Tarjeta(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  for (var i = 0; i < lista.length; i++) ...[
                    if (i > 0) const Divider(),
                    _Fila(
                      invitacion: lista[i],
                      ahora: ahora,
                      revocando: _revocando.contains(lista[i].id),
                      alRevocar: () => _revocar(lista[i]),
                    ),
                  ],
                ],
              ),
            ),
        ],
      ],
    );
  }
}

class _Fila extends StatelessWidget {
  const _Fila({
    required this.invitacion,
    required this.ahora,
    required this.revocando,
    required this.alRevocar,
  });

  final Invitacion invitacion;
  final DateTime ahora;
  final bool revocando;
  final VoidCallback alRevocar;

  /// Rol, cupo (solo de un Usuario) y la fecha que importa según el estado.
  String _detalle(EstadoInvitacion estado) {
    final partes = <String>[
      etiquetaDeRol(invitacion.rol),
      if (invitacion.rol == RolApp.usuario)
        'Cupo inicial ${formatearUsd(invitacion.cupoInicial)}',
      switch (estado) {
        EstadoInvitacion.pendiente =>
          'Vence el ${formatearFechaHora(invitacion.expiraEn)}',
        EstadoInvitacion.vencida =>
          'Venció el ${formatearFechaHora(invitacion.expiraEn)}',
        EstadoInvitacion.aceptada =>
          'Aceptada el ${formatearFechaHora(invitacion.aceptadaEn ?? invitacion.creadoEn)}',
        EstadoInvitacion.revocada =>
          'Revocada el ${formatearFechaHora(invitacion.revocadaEn ?? invitacion.creadoEn)}',
      },
    ];
    return partes.join(' · ');
  }

  Widget _chip(EstadoInvitacion estado) => switch (estado) {
    EstadoInvitacion.pendiente => ChipDeEstado.pendiente(
      etiqueta: etiquetaDeEstado(estado),
    ),
    EstadoInvitacion.aceptada => ChipDeEstado(
      etiqueta: etiquetaDeEstado(estado),
      forma: FormaDeLinea.solida,
    ),
    EstadoInvitacion.vencida => ChipDeEstado.desactualizado(
      etiqueta: etiquetaDeEstado(estado),
    ),
    EstadoInvitacion.revocada => ChipDeEstado.deshabilitado(
      etiqueta: etiquetaDeEstado(estado),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final estado = invitacion.estadoVisible(ahora);
    final vigente = invitacion.estaVigente(ahora);
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: Espacio.x4,
        vertical: Espacio.x3,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: Espacio.x1),
                  child: Text(invitacion.email, style: textos.titleMedium),
                ),
              ),
              const SizedBox(width: Espacio.x3),
              _chip(estado),
            ],
          ),
          const SizedBox(height: Espacio.x1),
          Text(
            _detalle(estado),
            style: textos.bodyMedium!.copyWith(color: c.tintaSuave),
          ),
          if (vigente) ...[
            const SizedBox(height: Espacio.x1),
            Semantics(
              container: true,
              button: true,
              label: 'Revocar la invitación de ${invitacion.email}',
              excludeSemantics: true,
              onTap: revocando ? null : alRevocar,
              child: BotonTexto(
                texto: revocando ? textoProcesando : 'Revocar',
                icono: revocando ? null : Icons.block,
                alPresionar: revocando ? null : alRevocar,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Confirmación de la revocación: lo que exige decidir va en un diálogo (D-61).
class _DialogoDeRevocacion extends StatelessWidget {
  const _DialogoDeRevocacion({required this.email});

  final String email;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('¿Revocar la invitación?'),
      content: Text(
        '$email ya no podrá entrar con ella. Puedes invitarla de nuevo '
        'cuando quieras.',
      ),
      actions: [
        BotonSecundario(
          texto: 'Cancelar',
          alPresionar: () => Navigator.of(context).pop(false),
        ),
        BotonPrimario(
          texto: 'Revocar',
          alPresionar: () => Navigator.of(context).pop(true),
        ),
      ],
    );
  }
}
