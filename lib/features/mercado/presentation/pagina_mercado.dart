/// Pantalla de mercado en vivo (HU-030, FR-071, FR-072): el estado del mercado
/// con su cuenta regresiva, la gráfica del símbolo elegido (abre en QQQ) y la
/// lista del universo con su precio y su variación del día, que se mueven solas
/// con el canal `mercado`. Se diseña primero para el celular (360–412 dp).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../core/realtime/reloj.dart';
import '../../../shared/widgets/estados.dart';
import '../../../shared/widgets/opciones_excluyentes.dart';
import '../../../shared/widgets/tarjeta.dart';
import '../../../shared/widgets/tarjeta_de_cotizacion.dart';
import '../domain/mercado.dart';
import 'encabezado_del_mercado.dart';
import 'grafica_de_mercado.dart';
import 'mercado_provider.dart';

/// Agrega el punto en vivo al final de la serie: así la línea sigue al precio
/// que llega por el canal sin volver a pedir las barras.
List<PuntoDeSerie> serieConPrecioEnVivo(
  List<PuntoDeSerie> serie,
  Cotizacion? cotizacion,
) {
  if (cotizacion == null || serie.isEmpty) return serie;
  if (!cotizacion.momento.isAfter(serie.last.momento)) return serie;
  return [...serie, PuntoDeSerie(cotizacion.momento, cotizacion.precio)];
}

/// El cambio porcentual entre el primer y el último punto de la serie.
double? variacionDeLaSerie(List<PuntoDeSerie> serie) {
  if (serie.length < 2 || serie.first.valor == 0) return null;
  return (serie.last.valor / serie.first.valor - 1) * 100;
}

class PaginaMercado extends ConsumerWidget {
  const PaginaMercado({this.pie = const [], super.key});

  /// Contenido al final de la pantalla (avisos de configuración, accesos).
  final List<Widget> pie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(listaBlancaProvider);
    final cotizaciones = ref.watch(cotizacionesProvider);
    final bolsillo = ref.watch(bolsilloElegidoProvider);
    final graficado = ref.watch(simboloGraficadoProvider);

    final cargando = lista.isLoading || cotizaciones.isLoading;
    final error = lista.hasError && !lista.hasValue
        ? lista.error
        : (cotizaciones.hasError && !cotizaciones.hasValue
              ? cotizaciones.error
              : null);

    final filas = (lista.hasValue && cotizaciones.hasValue)
        ? filasDeMercado(
            lista: lista.requireValue,
            cotizaciones: cotizaciones.requireValue,
            bolsillo: bolsillo,
          )
        : const <FilaDeMercado>[];

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        Espacio.x4,
        Espacio.x3,
        Espacio.x4,
        Espacio.x8,
      ),
      children: [
        const EncabezadoDelMercado(),
        const SizedBox(height: Espacio.x4),
        _TarjetaDeGrafica(
          simbolo: graficado,
          cotizacion: cotizaciones.value?[graficado],
          nombre: _nombreDe(graficado, lista.value),
        ),
        const SizedBox(height: Espacio.x4),
        OpcionesExcluyentes<BolsilloDeLista?>(
          etiqueta: 'Lista blanca',
          valor: bolsillo,
          alElegir: ref.read(bolsilloElegidoProvider.notifier).elegir,
          opciones: [
            const OpcionExcluyente(valor: null, etiqueta: 'Todos'),
            for (final b in BolsilloDeLista.values)
              OpcionExcluyente(valor: b, etiqueta: b.etiqueta),
          ],
        ),
        const SizedBox(height: Espacio.x3),
        if (error != null)
          EstadoDeError(
            error: error,
            alReintentar: () {
              ref.invalidate(listaBlancaProvider);
              ref.invalidate(cotizacionesProvider);
            },
          )
        else if (cargando && filas.isEmpty)
          const EstadoCargando(lineas: 4)
        else if (filas.isEmpty)
          const EstadoVacio(
            titulo: 'Sin símbolos',
            mensaje:
                'Este bolsillo no tiene símbolos activos en la lista blanca.',
          )
        else
          Tarjeta(
            padding: EdgeInsets.zero,
            child: Column(
              children: [
                for (var i = 0; i < filas.length; i++) ...[
                  if (i > 0) Divider(height: 1, color: context.colores.regla),
                  _FilaDeLista(
                    fila: filas[i],
                    elegida: filas[i].simbolo == graficado,
                  ),
                ],
              ],
            ),
          ),
        ...pie,
      ],
    );
  }

  static String _nombreDe(String simbolo, List<SimboloDeLista>? lista) {
    for (final s in lista ?? const <SimboloDeLista>[]) {
      if (s.simbolo == simbolo) return s.nombre;
    }
    return simbolo;
  }
}

class _FilaDeLista extends ConsumerWidget {
  const _FilaDeLista({required this.fila, required this.elegida});

  final FilaDeMercado fila;
  final bool elegida;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final c = context.colores;
    final cotizacion = fila.cotizacion;
    void elegir() =>
        ref.read(simboloGraficadoProvider.notifier).elegir(fila.simbolo);
    final contenido = cotizacion == null
        ? InkWell(
            onTap: elegir,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 60),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: Espacio.x3,
                  vertical: Espacio.x2,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fila.simbolo,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          Text(
                            fila.nombre,
                            style: Theme.of(context).textTheme.bodySmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    Text(
                      'Sin precio',
                      style: Theme.of(context).textTheme.bodySmall!
                          .copyWith(color: c.tintaSuave),
                    ),
                  ],
                ),
              ),
            ),
          )
        : FilaDeCotizacion(
            simbolo: fila.simbolo,
            nombre: fila.nombre,
            precio: cotizacion.precio,
            variacion: _variacionDe(cotizacion),
            antiguedad: _antiguedad(ref, cotizacion),
            alTocar: elegir,
          );
    return DecoratedBox(
      decoration: BoxDecoration(color: elegida ? c.moradoTenue : null),
      child: contenido,
    );
  }

  static double _variacionDe(Cotizacion c) {
    final dada = c.variacionDiaPct;
    if (dada != null) return dada;
    final anterior = c.cierreAnterior;
    if (anterior != null && anterior != 0) {
      return (c.precio / anterior - 1) * 100;
    }
    return 0;
  }

  static Duration _antiguedad(WidgetRef ref, Cotizacion c) {
    final d = ref.read(relojProvider).ahora().difference(c.recibidoEn);
    return d.isNegative ? Duration.zero : d;
  }
}

/// La gráfica del símbolo elegido con su precio, su cambio y el selector de
/// rango 1D · 1M · 1Y · All.
class _TarjetaDeGrafica extends ConsumerWidget {
  const _TarjetaDeGrafica({
    required this.simbolo,
    required this.nombre,
    required this.cotizacion,
  });

  final String simbolo;
  final String nombre;
  final Cotizacion? cotizacion;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    final rango = ref.watch(rangoElegidoProvider);
    final clave = (simbolo: simbolo, rango: rango);
    final serie = ref.watch(serieProvider(clave));

    final puntos = serie.hasValue
        ? serieConPrecioEnVivo(serie.requireValue, cotizacion)
        : const <PuntoDeSerie>[];
    final precio =
        cotizacion?.precio ?? (puntos.isEmpty ? null : puntos.last.valor);
    final variacion = rango == RangoDeGrafica.dia
        ? (cotizacion?.variacionDiaPct ?? variacionDeLaSerie(puntos))
        : variacionDeLaSerie(puntos);

    return Tarjeta(
      padding: const EdgeInsets.fromLTRB(
        Espacio.x4,
        Espacio.x4,
        Espacio.x3,
        Espacio.x2,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            nombre == simbolo ? simbolo : '$simbolo · $nombre',
            style: textos.titleMedium,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: Espacio.x1),
          Wrap(
            crossAxisAlignment: WrapCrossAlignment.end,
            spacing: Espacio.x3,
            children: [
              Text(
                precio == null ? '—' : 'USD ${etiquetaDePrecio(precio)}',
                style: textos.headlineSmall!.copyWith(
                  fontFamily: familiaMonoespaciada,
                  fontWeight: FontWeight.w700,
                ),
              ),
              if (variacion != null)
                Text(
                  '${variacion >= 0 ? '+' : ''}${etiquetaDePrecio(variacion)} %',
                  style: textos.bodyMedium!.copyWith(
                    fontFamily: familiaMonoespaciada,
                    fontWeight: FontWeight.w600,
                    color: variacion >= 0 ? c.alza : c.baja,
                  ),
                ),
            ],
          ),
          const SizedBox(height: Espacio.x2),
          _SelectorDeRango(
            rango: rango,
            alElegir: ref.read(rangoElegidoProvider.notifier).elegir,
          ),
          const SizedBox(height: Espacio.x2),
          if (serie.hasError && !serie.hasValue)
            Padding(
              padding: const EdgeInsets.only(bottom: Espacio.x2),
              child: EstadoDeError(
                error: serie.error,
                alReintentar: () => ref.invalidate(serieProvider(clave)),
              ),
            )
          else if (serie.isLoading && !serie.hasValue)
            const SizedBox(
              height: 220,
              child: Center(child: CircularProgressIndicator()),
            )
          else if (puntos.isEmpty)
            SizedBox(
              height: 220,
              child: Center(
                child: Text(
                  rango == RangoDeGrafica.dia
                      ? 'Sin datos del día para $simbolo'
                      : 'Sin datos de este rango para $simbolo',
                  style: textos.bodyMedium!.copyWith(color: c.tintaSuave),
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            GraficaDeMercado(
              serie: puntos,
              rango: rango,
              descripcion:
                  '$simbolo, ${rango.etiqueta}: de ${etiquetaDePrecio(puntos.first.valor)} a ${etiquetaDePrecio(puntos.last.valor)}',
            ),
        ],
      ),
    );
  }
}

/// El selector 1D · 1M · 1Y · All: botones de texto; el elegido lleva una
/// píldora tenue del morado. Cada uno mide al menos 48 dp de alto.
class _SelectorDeRango extends StatelessWidget {
  const _SelectorDeRango({required this.rango, required this.alElegir});

  final RangoDeGrafica rango;
  final ValueChanged<RangoDeGrafica> alElegir;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return Row(
      children: [
        for (final r in RangoDeGrafica.values)
          Expanded(
            child: Semantics(
              button: true,
              selected: r == rango,
              label: 'Rango ${r.etiqueta}',
              excludeSemantics: true,
              child: InkWell(
                key: ValueKey('rango-${r.etiqueta}'),
                onTap: () => alElegir(r),
                borderRadius: BorderRadius.circular(999),
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: Espacio.objetivoTactil,
                  ),
                  child: Center(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: r == rango ? c.moradoTenue : null,
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: Espacio.x3,
                          vertical: Espacio.x1,
                        ),
                        child: Text(
                          r.etiqueta,
                          style: textos.bodyMedium!.copyWith(
                            fontFamily: familiaMonoespaciada,
                            fontWeight: r == rango
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: r == rango ? c.morado : c.tintaSuave,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
