/// Isla de navegación del teléfono: una cápsula flotante, centrada abajo, con
/// velo y desenfoque de lo que flota. La pestaña actual muestra ícono y rótulo
/// dentro de una píldora `morado-tenue`; las demás, solo el ícono. En ventanas
/// anchas la pantalla usa el riel de navegación y no este componente.
///
/// La pantalla que la usa pone `extendBody: true` en su `Scaffold` y deja al
/// final de sus listas el relleno inferior de `MediaQuery` más `Espacio.x4`.
library;

import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../../app/tema.dart';

/// Un destino de la isla.
class Pestana {
  const Pestana({
    required this.etiqueta,
    required this.icono,
    this.iconoActivo,
    this.clave,
  });

  final String etiqueta;
  final IconData icono;
  final IconData? iconoActivo;

  /// Identifica el destino en las pruebas (la isla y el riel de navegación
  /// usan la misma clave para el mismo destino).
  final Key? clave;
}

class BarraDePestanas extends StatelessWidget {
  const BarraDePestanas({
    required this.pestanas,
    required this.actual,
    required this.alElegir,
    super.key,
  });

  final List<Pestana> pestanas;
  final int actual;
  final ValueChanged<int> alElegir;

  @override
  Widget build(BuildContext context) {
    final p = context.profundidad;
    const forma = StadiumBorder();
    final duracion = MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : Duracion.transicion;
    Widget destino(int i, Pestana pestana) => _Destino(
      key: pestana.clave,
      pestana: pestana,
      actual: i == actual,
      duracion: duracion,
      alElegir: () => alElegir(i),
    );
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.only(bottom: Espacio.x4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: Espacio.x4),
        child: Align(
          alignment: Alignment.bottomCenter,
          heightFactor: 1,
          child: DecoratedBox(
            decoration: ShapeDecoration(
              shape: forma,
              shadows: p.sombraFlotante,
            ),
            child: ClipPath(
              clipper: ShapeBorderClipper(shape: forma),
              child: BackdropFilter(
                filter: ui.ImageFilter.blur(
                  sigmaX: ProfundidadAlmanaque.desenfoque,
                  sigmaY: ProfundidadAlmanaque.desenfoque,
                ),
                child: DecoratedBox(
                  decoration: ShapeDecoration(shape: forma, color: p.velo),
                  child: Padding(
                    padding: const EdgeInsets.all(Espacio.x1),
                    // Los rótulos escalan hasta 1,4×: con más, la píldora de
                    // la pestaña actual no cabe en 360 dp. El rótulo se
                    // recorta con puntos suspensivos; el lector de pantalla y
                    // la descripción emergente leen el nombre completo.
                    child: MediaQuery.withClampedTextScaling(
                      maxScaleFactor: 1.4,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Solo la actual cede espacio: las demás miden
                          // lo que su ícono y la actual recibe el resto.
                          for (final (i, pestana) in pestanas.indexed)
                            if (i == actual)
                              Flexible(child: destino(i, pestana))
                            else
                              destino(i, pestana),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Destino extends StatefulWidget {
  const _Destino({
    super.key,
    required this.pestana,
    required this.actual,
    required this.duracion,
    required this.alElegir,
  });

  final Pestana pestana;
  final bool actual;
  final Duration duracion;
  final VoidCallback alElegir;

  @override
  State<_Destino> createState() => _DestinoState();
}

class _DestinoState extends State<_Destino> {
  bool _enfocado = false;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final pestana = widget.pestana;
    final actual = widget.actual;
    final color = actual ? c.tinta : c.tintaSuave;
    final estiloRotulo = Theme.of(context).textTheme.bodySmall!.copyWith(
      fontFamily: Familias.condensada,
      fontSize: 12,
      color: color,
      fontWeight: actual ? FontWeight.w700 : FontWeight.w600,
    );
    return Semantics(
      container: true,
      button: true,
      selected: actual,
      label: pestana.etiqueta,
      onTap: widget.alElegir,
      child: ExcludeSemantics(
        child: Tooltip(
          message: pestana.etiqueta,
          excludeFromSemantics: true,
          child: AnimatedContainer(
            duration: widget.duracion,
            curve: Curves.easeOut,
            constraints: const BoxConstraints(
              minWidth: Espacio.objetivoTactil,
              minHeight: Espacio.objetivoTactil,
            ),
            decoration: ShapeDecoration(
              shape: StadiumBorder(
                side: _enfocado
                    ? BorderSide(color: c.morado, width: 2)
                    : BorderSide.none,
              ),
              color: actual ? c.moradoTenue : const Color(0x00000000),
            ),
            child: InkWell(
              customBorder: const StadiumBorder(),
              onTap: widget.alElegir,
              onFocusChange: (v) => setState(() => _enfocado = v),
              child: AnimatedSize(
                duration: widget.duracion,
                curve: Curves.easeOut,
                alignment: Alignment.centerLeft,
                child: Padding(
                  padding: EdgeInsets.symmetric(
                    horizontal: actual ? Espacio.x3 : 0,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: actual ? 0 : Espacio.x3,
                          vertical: Espacio.x3,
                        ),
                        child: Icon(
                          actual
                              ? (pestana.iconoActivo ?? pestana.icono)
                              : pestana.icono,
                          size: 24,
                          color: color,
                        ),
                      ),
                      if (actual) ...[
                        const SizedBox(width: Espacio.x2),
                        Flexible(
                          child: Text(
                            pestana.etiqueta,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: estiloRotulo,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
