/// Pantalla de Parámetros e Interruptores del Administrador (HU-101, PM-54,
/// PM-56 y PM-57).
///
/// Dos vistas: los parámetros de docs/02 §10 agrupados por tema, con su valor,
/// su rango y su descripción, y los dos interruptores del fondo. Es experiencia
/// de uso, no seguridad: a esta ruta solo llega el Administrador (guarda de
/// `/admin/*`, HU-006) y cada cambio lo valida la base de datos.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/tema.dart';
import '../../../../shared/widgets/barra_superior.dart';
import '../../../../shared/widgets/estados.dart';
import '../../../../shared/widgets/hoja_inferior.dart';
import '../../../../shared/widgets/opciones_excluyentes.dart';
import '../../../../shared/widgets/tarjeta.dart';
import '../domain/parametro.dart';
import '../domain/valor_de_parametro.dart';
import 'edicion_de_parametro.dart';
import 'panel_de_interruptores.dart';
import 'parametros_provider.dart';

/// Ancho máximo del contenido en ventanas anchas.
const double anchoMaximoDeParametros = 720;

enum VistaDeParametros { parametros, interruptores }

/// Clave de la fila de un parámetro (o de `reparto`), para las pruebas.
Key claveDeParametro(String clave) => Key('parametro-$clave');

class PaginaParametros extends ConsumerStatefulWidget {
  const PaginaParametros({super.key});

  @override
  ConsumerState<PaginaParametros> createState() => _PaginaParametrosState();
}

class _PaginaParametrosState extends ConsumerState<PaginaParametros> {
  VistaDeParametros _vista = VistaDeParametros.parametros;

  Future<void> _recargar() async {
    ref
      ..invalidate(parametrosProvider)
      ..invalidate(interruptoresProvider);
    await ref.read(parametrosProvider.future).catchError((_) => <Parametro>[]);
  }

  @override
  Widget build(BuildContext context) {
    final abajo = MediaQuery.paddingOf(context).bottom + Espacio.x8;
    return Scaffold(
      appBar: const BarraSuperior(titulo: 'Parámetros e interruptores'),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: anchoMaximoDeParametros),
          child: RefreshIndicator(
            onRefresh: _recargar,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: EdgeInsets.fromLTRB(
                Espacio.x4,
                Espacio.x4,
                Espacio.x4,
                abajo,
              ),
              children: [
                OpcionesExcluyentes<VistaDeParametros>(
                  etiqueta: 'Ver',
                  opciones: const [
                    OpcionExcluyente(
                      valor: VistaDeParametros.parametros,
                      etiqueta: 'Parámetros',
                    ),
                    OpcionExcluyente(
                      valor: VistaDeParametros.interruptores,
                      etiqueta: 'Interruptores',
                    ),
                  ],
                  valor: _vista,
                  alElegir: (v) => setState(() => _vista = v),
                ),
                const SizedBox(height: Espacio.x4),
                if (_vista == VistaDeParametros.interruptores)
                  const PanelDeInterruptores()
                else
                  ..._parametros(ref.watch(parametrosProvider)),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _parametros(AsyncValue<List<Parametro>> estado) {
    return switch (estado) {
      AsyncData(:final value) => _grupos(context, value),
      AsyncError(:final error) => [
        EstadoDeError(error: error, alReintentar: _recargar),
      ],
      _ => const [EstadoCargando(lineas: 5)],
    };
  }

  List<Widget> _grupos(BuildContext context, List<Parametro> todos) {
    final textos = Theme.of(context).textTheme;
    final temas = <String, List<Parametro>>{};
    for (final p in todos) {
      temas.putIfAbsent(p.tema, () => []).add(p);
    }
    final reparto = todos.where((p) => p.esReparto).toList();
    return [
      for (final MapEntry(key: tema, value: lista) in temas.entries) ...[
        Padding(
          padding: const EdgeInsets.only(top: Espacio.x2, bottom: Espacio.x2),
          child: Text(tituloDeTema(tema), style: textos.titleSmall),
        ),
        if (tema == 'reparto')
          _FilaDeParametro(
            key: claveDeParametro('reparto'),
            titulo: 'Reparto de cada aporte',
            descripcion: 'Reserva, Arriesgadas y Usuarios: se cambian juntos y suman 100.',
            valor: reparto.map((p) => textoDeValor(p.valor)).join(' / '),
            alTocar: () => mostrarHojaInferior<void>(
              context,
              constructor: (_) => EdicionDelReparto(parametros: reparto),
            ),
          )
        else
          for (final p in lista)
            _FilaDeParametro(
              key: claveDeParametro(p.clave),
              titulo: p.clave,
              descripcion: p.descripcion,
              valor: p.valorEnTexto,
              rango: p.rango,
              alTocar: () => mostrarHojaInferior<void>(
                context,
                constructor: (_) => EdicionDeParametro(parametro: p),
              ),
            ),
        const SizedBox(height: Espacio.x2),
      ],
    ];
  }
}

class _FilaDeParametro extends StatelessWidget {
  const _FilaDeParametro({
    required this.titulo,
    required this.descripcion,
    required this.valor,
    required this.alTocar,
    this.rango,
    super.key,
  });

  final String titulo;
  final String descripcion;
  final String valor;
  final String? rango;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final suave = textos.bodyMedium!.copyWith(
      color: context.colores.tintaSuave,
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: Espacio.x2),
      child: Tarjeta(
        alTocar: alTocar,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: Text(titulo, style: textos.bodyMedium)),
                const SizedBox(width: Espacio.x3),
                Text(valor, style: textos.titleMedium),
              ],
            ),
            const SizedBox(height: Espacio.x1),
            Text(descripcion, style: suave),
            if (rango != null) Text('Rango: $rango', style: suave),
          ],
        ),
      ),
    );
  }
}
