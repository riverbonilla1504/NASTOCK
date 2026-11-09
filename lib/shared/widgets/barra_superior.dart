/// Barra superior blanca con borde inferior fino (D-69).
///
/// Lleva el título de la pantalla y, debajo, lo que la pantalla necesite: en
/// Mercado, la franja de la jornada. Como `appBar` de un `Scaffold` necesita
/// [alturaInferior]; con un [inferior] que cambia de alto (texto grande), va
/// arriba del cuerpo y crece con su contenido.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

import '../../app/tema.dart';

class BarraSuperior extends StatelessWidget implements PreferredSizeWidget {
  const BarraSuperior({
    required this.titulo,
    this.acciones = const [],
    this.inferior,
    this.alturaInferior,
    super.key,
  });

  final String titulo;
  final List<Widget> acciones;

  /// Contenido bajo el título, sobre la misma barra.
  final Widget? inferior;

  /// Alto fijo para [inferior] (con su margen), solo si va como `appBar`.
  final double? alturaInferior;

  @override
  Size get preferredSize =>
      Size.fromHeight(kToolbarHeight + (alturaInferior ?? 0));

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final puedeVolver = ModalRoute.of(context)?.canPop ?? false;
    final claro = Theme.of(context).brightness == Brightness.light;
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: claro ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: c.hoja,
          border: Border(bottom: BorderSide(color: c.regla)),
        ),
        child: Padding(
          padding: EdgeInsets.only(top: MediaQuery.paddingOf(context).top),
          child: IconTheme(
            data: IconThemeData(color: c.tinta),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(
                  height: kToolbarHeight,
                  child: Row(
                    children: [
                      if (puedeVolver)
                        BackButton(color: c.tinta)
                      else
                        const SizedBox(width: Espacio.x4),
                      Expanded(
                        child: Semantics(
                          header: true,
                          child: Text(
                            titulo,
                            style: textos.headlineSmall,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ),
                      ...acciones,
                      const SizedBox(width: Espacio.x1),
                    ],
                  ),
                ),
                if (inferior != null)
                  SizedBox(
                    height: alturaInferior,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        Espacio.x4,
                        0,
                        Espacio.x4,
                        Espacio.x3,
                      ),
                      child: DefaultTextStyle(
                        style: textos.bodyMedium!,
                        child: inferior!,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
