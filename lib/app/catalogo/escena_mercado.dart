/// Escena de ejemplo: cómo se ven juntas las piezas del sistema en una
/// pantalla de Mercado. No es la pantalla de HU-030: los datos son de ejemplo.
library;

import 'package:flutter/material.dart';

import '../../shared/widgets/avisos.dart';
import '../../shared/widgets/barra_de_pestanas.dart';
import '../../shared/widgets/barra_superior.dart';
import '../../shared/widgets/botones.dart';
import '../../shared/widgets/forma_de_linea.dart';
import '../../shared/widgets/franja_de_la_jornada.dart';
import '../../shared/widgets/tarjeta.dart';
import '../../shared/widgets/tarjeta_de_cotizacion.dart';
import '../tema.dart';
import 'datos_de_ejemplo.dart';
import 'pagina_catalogo.dart';

class EscenaMercado extends StatefulWidget {
  const EscenaMercado({this.mostrarAviso = false, super.key});

  /// Muestra el aviso temporal al abrir y lo deja visible (para capturas).
  final bool mostrarAviso;

  @override
  State<EscenaMercado> createState() => _EscenaMercadoState();
}

class _EscenaMercadoState extends State<EscenaMercado> {
  int _pestana = 0;

  @override
  void initState() {
    super.initState();
    if (widget.mostrarAviso) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _mostrarAviso(largo: true);
      });
    }
  }

  void _mostrarAviso({bool largo = false}) => mostrarAvisoTemporal(
    context,
    'Parámetro guardado',
    accion: 'Ver',
    alAccionar: () {},
    duracion: largo ? const Duration(minutes: 5) : const Duration(seconds: 4),
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBody: true,
      body: Column(
        children: [
          const BarraSuperior(
            titulo: 'Mercado',
            acciones: [InterruptorDeTema()],
            inferior: _BloqueDeJornada(),
          ),
          Expanded(
            child: MediaQuery.removePadding(
              context: context,
              removeTop: true,
              child: _Contenido(alMostrarAviso: _mostrarAviso),
            ),
          ),
        ],
      ),
      // Sin botón flotante: en una lista con cifras a la derecha taparía
      // precios y marcas de dato desactualizado (DESIGN.md). La acción va en
      // la tarjeta de detalle.
      bottomNavigationBar: BarraDePestanas(
        actual: _pestana,
        alElegir: (i) => setState(() => _pestana = i),
        pestanas: const [
          Pestana(etiqueta: 'Mercado', icono: Icons.show_chart),
          Pestana(etiqueta: 'Oportunidades', icono: Icons.query_stats),
          Pestana(
            etiqueta: 'Mi cupo',
            icono: Icons.account_balance_wallet_outlined,
          ),
          Pestana(etiqueta: 'Alertas', icono: Icons.notifications_none),
        ],
      ),
    );
  }
}

class _Contenido extends StatelessWidget {
  const _Contenido({required this.alMostrarAviso});

  final VoidCallback alMostrarAviso;

  @override
  Widget build(BuildContext context) {
    final textos = Theme.of(context).textTheme;
    final c = context.colores;
    return ListView(
      // Relleno inferior: lo que ocupa la isla (MediaQuery, por `extendBody`)
      // más aire, para que la última fila no quede tapada.
      padding: EdgeInsets.fromLTRB(
        Espacio.x4,
        Espacio.x4,
        Espacio.x4,
        MediaQuery.paddingOf(context).bottom + Espacio.x4,
      ),
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.baseline,
          textBaseline: TextBaseline.alphabetic,
          children: [
            Expanded(child: Text('Seguimiento', style: textos.titleLarge)),
            Text(
              'Datos de ejemplo',
              style: textos.bodySmall!.copyWith(color: c.tintaSuave),
            ),
          ],
        ),
        const SizedBox(height: Espacio.x3),
        Tarjeta(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              for (final (i, f) in Ejemplo.filas.indexed) ...[
                if (i > 0) const Divider(),
                FilaDeCotizacion(
                  simbolo: f.simbolo,
                  nombre: f.nombre,
                  factor: f.factor,
                  precio: f.precio,
                  variacion: f.variacion,
                  antiguedad: f.antiguedad,
                  desactualizado: f.desactualizado,
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: Espacio.x6),
        Text('Detalle', style: textos.titleLarge),
        const SizedBox(height: Espacio.x3),
        TarjetaDeCotizacion(
          simbolo: 'QLD',
          nombre: 'ProShares Ultra QQQ',
          factor: '×2',
          precio: 98.14,
          variacion: 2.47,
          antiguedad: const Duration(seconds: 8),
          curva: Ejemplo.curvaQld,
          ahora: Ejemplo.fraccionAhora,
          etiquetasDelEje: const ['09:30', 'ahora 11:46', '16:00'],
          acciones: [
            BotonPrimario(texto: 'Comprar', alPresionar: () {}),
            BotonSecundario(texto: 'Vender', alPresionar: () {}),
          ],
        ),
        const SizedBox(height: Espacio.x4),
        Align(
          alignment: Alignment.centerLeft,
          child: BotonSecundario(
            texto: 'Mostrar aviso temporal',
            alPresionar: alMostrarAviso,
          ),
        ),
      ],
    );
  }
}

class _BloqueDeJornada extends StatelessWidget {
  const _BloqueDeJornada();

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final suave = textos.bodySmall!.copyWith(color: c.tintaSuave);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('Jornada de hoy · viernes 6 nov', style: suave),
            ),
            TrazoDeLinea(forma: FormaDeLinea.solida, color: c.tinta),
            const SizedBox(width: Espacio.x2),
            Text(
              'ABIERTO',
              style: textos.labelMedium!.copyWith(color: c.tinta),
            ),
          ],
        ),
        const SizedBox(height: Espacio.x1),
        FranjaDeLaJornada(
          apertura: Ejemplo.apertura,
          cierre: Ejemplo.cierre,
          ahora: Ejemplo.ahora,
        ),
        Text.rich(
          TextSpan(
            children: [
              TextSpan(
                text: 'Cierra en 4 h 14 min',
                style: textos.bodyMedium!.copyWith(
                  color: c.tinta,
                  fontWeight: FontWeight.w600,
                ),
              ),
              TextSpan(text: ' · hora de Bogotá', style: suave),
            ],
          ),
        ),
      ],
    );
  }
}
