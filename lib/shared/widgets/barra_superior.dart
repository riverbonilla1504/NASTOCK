/// Barra superior de título grande (D-69, opción A de Javier, 2026-11-17).
///
/// En reposo no es una barra: el título va grande (headline large, 28 px) sobre
/// el mismo `papel` de la pantalla, sin borde, con los íconos arriba a la
/// derecha y la flecha de volver a la izquierda. Cuando el contenido de la
/// pantalla se desplaza hacia abajo, el título grande se recoge y la barra
/// queda compacta, con el título en 20 px y el borde inferior de 1 px. Al
/// volver arriba, el título grande regresa. Escucha el desplazamiento con el
/// `ScrollNotificationObserver` del `Scaffold`, como `AppBar`.
///
/// Debajo puede llevar lo que la pantalla necesite (en Mercado, la franja de la
/// jornada). Como `appBar` de un `Scaffold` necesita [alturaInferior]; con un
/// [inferior] que cambia de alto (texto grande), va arriba del cuerpo y crece
/// con su contenido.
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show SystemUiOverlayStyle;

import '../../app/tema.dart';

/// Lo más que mide la fila del título grande: 28 px escalado hasta 1,3 (más
/// el interlineado de 1,15) y sus márgenes de 4 y 12 dp.
const double altoMaximoDelTituloGrande = 58;

/// El título grande escala con el texto del sistema hasta este factor; a 1,3
/// ya mide más que el título compacto al doble (docs/15 §12, WCAG 1.4.4).
const double _escalaMaximaDelTituloGrande = 1.3;

/// Desde cuántos dp de desplazamiento se recoge el título grande.
const double _umbralDeRecogida = 8;

class BarraSuperior extends StatefulWidget implements PreferredSizeWidget {
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

  /// El alto máximo, con el título grande: el `Scaffold` deja que la barra
  /// mida menos y el cuerpo empieza donde ella termina.
  @override
  Size get preferredSize => Size.fromHeight(
    kToolbarHeight + altoMaximoDelTituloGrande + (alturaInferior ?? 0),
  );

  @override
  State<BarraSuperior> createState() => _BarraSuperiorState();
}

class _BarraSuperiorState extends State<BarraSuperior> {
  ScrollNotificationObserverState? _observador;
  bool _recogida = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _observador?.removeListener(_alDesplazar);
    _observador = ScrollNotificationObserver.maybeOf(context);
    _observador?.addListener(_alDesplazar);
  }

  @override
  void dispose() {
    _observador?.removeListener(_alDesplazar);
    _observador = null;
    super.dispose();
  }

  void _alDesplazar(ScrollNotification aviso) {
    // Solo el desplazamiento vertical principal de la pantalla, como AppBar:
    // ni las listas horizontales ni las anidadas.
    if (aviso is! ScrollUpdateNotification || aviso.depth != 0) return;
    if (aviso.metrics.axis != Axis.vertical) return;
    final recorrido = aviso.metrics.pixels - aviso.metrics.minScrollExtent;
    final recogida = recorrido > _umbralDeRecogida
        ? true
        : (recorrido <= 0 ? false : _recogida);
    if (recogida != _recogida && mounted) {
      setState(() => _recogida = recogida);
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final puedeVolver = ModalRoute.of(context)?.canPop ?? false;
    final claro = Theme.of(context).brightness == Brightness.light;
    final sinAnimaciones = MediaQuery.disableAnimationsOf(context);
    final grande = textos.headlineLarge!;
    // Lo que ocupa la línea del título grande, para que la fila no salte al
    // cambiar de un título al otro.
    final altoDeLinea =
        MediaQuery.textScalerOf(context)
            .clamp(maxScaleFactor: _escalaMaximaDelTituloGrande)
            .scale(grande.fontSize!) *
        (grande.height ?? 1);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: claro ? SystemUiOverlayStyle.dark : SystemUiOverlayStyle.light,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: _recogida ? 1 : 0),
        duration: sinAnimaciones ? Duration.zero : Duracion.transicion,
        curve: Curves.easeOutCubic,
        builder: (context, t, _) {
          // Un solo título a la vez: el grande en la primera mitad del cambio
          // y el compacto en la segunda, así el lector de pantalla y las
          // pruebas encuentran siempre uno.
          final compacto = t >= 0.5;
          return DecoratedBox(
            decoration: BoxDecoration(
              color: c.papel,
              border: Border(
                bottom: BorderSide(color: c.regla.withValues(alpha: t)),
              ),
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
                            child: compacto
                                ? Opacity(
                                    opacity: (t - 0.5) * 2,
                                    child: _Titulo(
                                      titulo: widget.titulo,
                                      estilo: textos.headlineSmall!,
                                    ),
                                  )
                                : const SizedBox.shrink(),
                          ),
                          ...widget.acciones,
                          const SizedBox(width: Espacio.x1),
                        ],
                      ),
                    ),
                    ClipRect(
                      child: Align(
                        alignment: Alignment.bottomLeft,
                        heightFactor: 1 - t,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Espacio.x4,
                            Espacio.x1,
                            Espacio.x4,
                            Espacio.x3,
                          ),
                          child: compacto
                              ? SizedBox(
                                  width: double.infinity,
                                  height: altoDeLinea,
                                )
                              : Opacity(
                                  opacity: 1 - t * 2,
                                  child: MediaQuery.withClampedTextScaling(
                                    maxScaleFactor:
                                        _escalaMaximaDelTituloGrande,
                                    child: _Titulo(
                                      titulo: widget.titulo,
                                      estilo: grande,
                                    ),
                                  ),
                                ),
                        ),
                      ),
                    ),
                    if (widget.inferior != null)
                      SizedBox(
                        height: widget.alturaInferior,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(
                            Espacio.x4,
                            0,
                            Espacio.x4,
                            Espacio.x3,
                          ),
                          child: DefaultTextStyle(
                            style: textos.bodyMedium!,
                            child: widget.inferior!,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _Titulo extends StatelessWidget {
  const _Titulo({required this.titulo, required this.estilo});

  final String titulo;
  final TextStyle estilo;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        titulo,
        style: estilo,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
