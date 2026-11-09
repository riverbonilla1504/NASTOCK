/// Selector de rango de una gráfica: 1D · 1M · 1Y · All, como en Alpaca (D-69).
///
/// Son botones de texto; el elegido lleva una píldora con el fondo tenue del
/// acento y el texto en negrita, así que se reconoce por la forma además del
/// color. Cada opción mide al menos 48 dp. En el celular se usa a todo el
/// ancho ([expandido]); en pantallas anchas se queda a la derecha del título.
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';

/// Los rangos que ofrece una gráfica, en orden.
enum RangoDeGrafica {
  dia('1D', 'Un día'),
  mes('1M', 'Un mes'),
  anio('1Y', 'Un año'),
  todo('All', 'Todo el período');

  const RangoDeGrafica(this.etiqueta, this.lectura);

  /// Lo que se ve en el botón.
  final String etiqueta;

  /// Lo que lee un lector de pantalla.
  final String lectura;
}

/// La clave de la opción de un rango, para las pruebas.
Key claveDeRango(RangoDeGrafica rango) => ValueKey('rango-${rango.name}');

class SelectorDeRango extends StatelessWidget {
  const SelectorDeRango({
    required this.rango,
    required this.alElegir,
    this.expandido = false,
    super.key,
  });

  /// El rango elegido.
  final RangoDeGrafica rango;

  /// Avisa el rango tocado. Con `null`, todos quedan deshabilitados.
  final ValueChanged<RangoDeGrafica>? alElegir;

  /// Reparte el ancho entre las opciones (celular).
  final bool expandido;

  @override
  Widget build(BuildContext context) {
    final opciones = [
      for (final r in RangoDeGrafica.values)
        _Opcion(
          key: claveDeRango(r),
          rango: r,
          elegido: r == rango,
          alElegir: alElegir == null ? null : () => alElegir!(r),
        ),
    ];
    return Semantics(
      container: true,
      label: 'Rango de la gráfica',
      child: Row(
        mainAxisSize: expandido ? MainAxisSize.max : MainAxisSize.min,
        children: [
          for (final o in opciones) expandido ? Expanded(child: o) : o,
        ],
      ),
    );
  }
}

class _Opcion extends StatelessWidget {
  const _Opcion({
    required this.rango,
    required this.elegido,
    required this.alElegir,
    super.key,
  });

  final RangoDeGrafica rango;
  final bool elegido;
  final VoidCallback? alElegir;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final habilitado = alElegir != null;
    final color = !habilitado
        ? c.tintaTenue
        : (elegido ? c.morado : c.tintaSuave);
    final estilo = estiloDeCifra(
      Theme.of(context).textTheme.labelMedium!.copyWith(
        color: color,
        fontWeight: elegido ? FontWeight.w700 : FontWeight.w500,
      ),
    );
    return Semantics(
      button: true,
      selected: elegido,
      enabled: habilitado,
      label: rango.lectura,
      onTap: alElegir,
      excludeSemantics: true,
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: alElegir,
          borderRadius: BorderRadius.circular(Radios.control),
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              minWidth: Espacio.objetivoTactil,
              minHeight: Espacio.objetivoTactil,
            ),
            child: Center(
              child: AnimatedContainer(
                duration: MediaQuery.disableAnimationsOf(context)
                    ? Duration.zero
                    : Duracion.estado,
                height: 32,
                padding: const EdgeInsets.symmetric(horizontal: Espacio.x3),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: elegido ? c.moradoTenue : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(rango.etiqueta, style: estilo),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
