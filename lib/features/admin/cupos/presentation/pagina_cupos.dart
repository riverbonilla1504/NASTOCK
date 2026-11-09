/// Pantalla de cupos del Administrador (HU-100, PM-42, RN-16 y RN-17): la bolsa
/// común y el cupo de cada empleado, con asignar y reducir.
///
/// Es experiencia de uso, no seguridad: a esta ruta solo llega el Administrador
/// (guarda de `/admin/*`, HU-006) y cada movimiento lo decide la RPC. La lista
/// se actualiza sola con los eventos del canal `fondo` (HU-084).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/tema.dart';
import '../../../../shared/widgets/barra_superior.dart';
import '../../../../shared/widgets/botones.dart';
import '../../../../shared/widgets/cifras.dart';
import '../../../../shared/widgets/estados.dart';
import '../../../../shared/widgets/hoja_inferior.dart';
import '../../../../shared/widgets/tarjeta.dart';
import '../domain/subcuenta_de_cupo.dart';
import 'cupos_provider.dart';
import 'formulario_de_movimiento_de_cupo.dart';

/// Ancho máximo del contenido en ventanas anchas.
const double anchoMaximoDeCupos = 720;

/// Clave de la tarjeta de la bolsa común, para las pruebas.
const Key claveDeLaBolsaComun = Key('cupos-bolsa-comun');

/// Clave de los botones de un cupo, para las pruebas.
Key claveDeAsignar(String usuarioId) => Key('cupo-asignar-$usuarioId');
Key claveDeReducir(String usuarioId) => Key('cupo-reducir-$usuarioId');

class PaginaCupos extends ConsumerWidget {
  const PaginaCupos({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estado = ref.watch(cuposProvider);
    final abajo = MediaQuery.paddingOf(context).bottom + Espacio.x8;

    Future<void> recargar() async {
      ref.invalidate(cuposProvider);
      await ref
          .read(cuposProvider.future)
          .catchError((_) => <SubcuentaDeCupo>[]);
    }

    return Scaffold(
      appBar: const BarraSuperior(titulo: 'Cupos'),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: anchoMaximoDeCupos),
          child: RefreshIndicator(
            onRefresh: recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                Espacio.x4,
                Espacio.x4,
                Espacio.x4,
                abajo,
              ),
              children: switch (estado) {
                AsyncData(:final value) => _contenido(context, value),
                AsyncError(:final error) => [
                  EstadoDeError(error: error, alReintentar: recargar),
                ],
                _ => const [EstadoCargando(lineas: 4)],
              },
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _contenido(BuildContext context, List<SubcuentaDeCupo> todas) {
    final bolsa = todas.where((s) => !s.esCupo).firstOrNull;
    final cupos = [
      for (final s in todas)
        if (s.esCupo) s,
    ];
    return [
      if (bolsa != null) _TarjetaDeBolsa(bolsa: bolsa),
      const SizedBox(height: Espacio.x4),
      if (cupos.isEmpty)
        const EstadoVacio(
          titulo: 'Aún no hay cupos',
          mensaje:
              'Cada Usuario recibe su cupo al aceptar la invitación. '
              'Cuando haya uno, aparece aquí para asignarle dinero.',
        )
      else
        for (final cupo in cupos) ...[
          _TarjetaDeCupo(cupo: cupo, bolsa: bolsa),
          const SizedBox(height: Espacio.x3),
        ],
    ];
  }
}

class _TarjetaDeBolsa extends StatelessWidget {
  const _TarjetaDeBolsa({required this.bolsa});

  final SubcuentaDeCupo bolsa;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final suave = textos.bodyMedium!.copyWith(
      color: context.colores.tintaSuave,
    );
    return Tarjeta(
      key: claveDeLaBolsaComun,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bolsa común de Usuarios', style: suave),
          const SizedBox(height: Espacio.x1),
          CifraUsd(bolsa.disponible, tamano: TamanoCifra.grande),
          const SizedBox(height: Espacio.x1),
          Text('Disponible para repartir en cupos', style: suave),
        ],
      ),
    );
  }
}

class _TarjetaDeCupo extends StatelessWidget {
  const _TarjetaDeCupo({required this.cupo, required this.bolsa});

  final SubcuentaDeCupo cupo;
  final SubcuentaDeCupo? bolsa;

  Widget _fila(BuildContext context, String etiqueta, double monto) {
    final suave = Theme.of(context).textTheme.bodyMedium!
        .copyWith(color: context.colores.tintaSuave);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: Espacio.x1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(etiqueta, style: suave),
          CifraUsd(monto, tamano: TamanoCifra.pequena),
        ],
      ),
    );
  }

  void _abrir(BuildContext context, AccionDeCupo accion) {
    mostrarHojaInferior<void>(
      context,
      constructor: (_) => FormularioDeMovimientoDeCupo(
        cupo: cupo,
        accion: accion,
        disponible: accion == AccionDeCupo.asignar
            ? (bolsa?.disponible ?? 0)
            : cupo.disponible,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final suave = textos.bodyMedium!.copyWith(
      color: context.colores.tintaSuave,
    );
    final id = cupo.usuarioId ?? cupo.id;
    return Tarjeta(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            cupo.titular ?? cupo.correo ?? 'Sin titular',
            style: textos.titleMedium,
          ),
          if (cupo.titular != null && cupo.correo != null)
            Text(cupo.correo!, style: suave),
          const SizedBox(height: Espacio.x2),
          _fila(context, 'Efectivo', cupo.efectivo),
          _fila(context, 'Disponible', cupo.disponible),
          _fila(context, 'Patrimonio', cupo.patrimonio),
          const SizedBox(height: Espacio.x3),
          Row(
            children: [
              Expanded(
                child: BotonPrimario(
                  key: claveDeAsignar(id),
                  texto: 'Asignar',
                  alPresionar: () => _abrir(context, AccionDeCupo.asignar),
                ),
              ),
              const SizedBox(width: Espacio.x3),
              Expanded(
                child: BotonSecundario(
                  key: claveDeReducir(id),
                  texto: 'Reducir',
                  alPresionar: () => _abrir(context, AccionDeCupo.reducir),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
