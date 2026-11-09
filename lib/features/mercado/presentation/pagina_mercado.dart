/// Pantalla de mercado en vivo (HU-030, FR-071, FR-072): el estado del mercado
/// con su cuenta regresiva, la gráfica del símbolo elegido (abre en QQQ) y la
/// lista del universo con su precio y su variación del día, que se mueven solas
/// con el canal `mercado`. Se diseña primero para el celular (360–412 dp).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/tema.dart';
import '../../../core/realtime/reloj.dart';
import '../../../shared/widgets/cifras.dart';
import '../../../shared/widgets/estados.dart';
import '../../../shared/widgets/opciones_excluyentes.dart';
import '../../../shared/widgets/selector_de_rango.dart';
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

  /// Contenido al principio de la pantalla (aviso de configuración y acceso
  /// al catálogo, que solo ve quien desarrolla).
  final List<Widget> pie;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lista = ref.watch(listaBlancaProvider);
    final cotizaciones = ref.watch(cotizacionesProvider);
    // Sin cotización en vivo (mercado cerrado) la lista usa el último cierre;
    // si el cierre falla, la lista sigue con lo que tenga.
    final cierres = ref.watch(ultimosCierresProvider).value ?? const {};
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
            cierres: cierres,
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
        ...pie,
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
    final cierre = fila.cierre;
    final contenido = cotizacion != null
        ? FilaDeCotizacion(
            simbolo: fila.simbolo,
            nombre: fila.nombre,
            precio: cotizacion.precio,
            variacion: _variacionDe(cotizacion),
            antiguedad: _antiguedad(ref, cotizacion),
            alTocar: elegir,
          )
        : _FilaSinCotizacion(fila: fila, cierre: cierre, alTocar: elegir);
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

/// Fila sin cotización en vivo: con el mercado cerrado muestra el último
/// cierre y su variación contra el cierre anterior, con la fecha de esa
/// sesión (`Cierre 6 nov`). Sin barras tampoco, dice "Sin precio".
class _FilaSinCotizacion extends StatelessWidget {
  const _FilaSinCotizacion({
    required this.fila,
    required this.cierre,
    required this.alTocar,
  });

  final FilaDeMercado fila;
  final CierreDiario? cierre;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    final cierre = this.cierre;
    final variacion = cierre?.variacionPct;
    return InkWell(
      onTap: alTocar,
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
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(fila.simbolo, style: textos.titleMedium),
                    Text(
                      fila.nombre,
                      style: textos.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: Espacio.x3),
              Expanded(
                flex: 3,
                child: cierre == null
                    ? Align(
                        alignment: Alignment.centerRight,
                        child: Text(
                          'Sin precio',
                          style: textos.bodySmall!.copyWith(
                            color: c.tintaSuave,
                          ),
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          CifraUsd(cierre.cierre),
                          Wrap(
                            alignment: WrapAlignment.end,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: Espacio.x2,
                            children: [
                              if (variacion != null) Variacion(variacion),
                              Text(
                                'Cierre ${fechaCorta(cierre.fecha)}',
                                style: textos.bodySmall!.copyWith(
                                  color: c.tintaSuave,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
            ],
          ),
        ),
      ),
    );
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
          if (precio != null) ...[
            Align(
              alignment: Alignment.centerLeft,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: CifraUsd(precio, tamano: TamanoCifra.grande),
              ),
            ),
            if (variacion != null) ...[
              const SizedBox(height: Espacio.x1),
              Align(
                alignment: Alignment.centerLeft,
                child: Variacion(variacion),
              ),
            ],
          ] else
            Text('—', style: textos.displaySmall),
          const SizedBox(height: Espacio.x2),
          SelectorDeRango(
            rango: rango,
            alElegir: ref.read(rangoElegidoProvider.notifier).elegir,
            expandido: true,
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
