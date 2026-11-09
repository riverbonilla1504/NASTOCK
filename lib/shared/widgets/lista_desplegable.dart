/// Lista desplegable: una sola opción visible que, al tocarla, abre la lista
/// de las demás (por ejemplo, el bolsillo de Mercado o el rol de una
/// invitación). Tiene la misma forma que [OpcionesExcluyentes] (etiqueta,
/// valor, alElegir y opciones), así que pasar de una a otra es cambiar el
/// nombre del widget.
///
/// Estilo Alpaca (D-69), pensado para el celular: ocupa todo el ancho, mide al
/// menos 48 dp de alto, lleva un borde fino y la flecha a la derecha. La
/// opción elegida se reconoce por el visto además de por la negrita. Con
/// texto grande la etiqueta pasa a otra línea en vez de desbordar.
library;

import 'package:flutter/material.dart';

import '../../app/tema.dart';
import 'campo.dart';
import 'opciones_excluyentes.dart' show OpcionExcluyente;

export 'opciones_excluyentes.dart' show OpcionExcluyente;

class ListaDesplegable<T> extends StatelessWidget {
  const ListaDesplegable({
    required this.etiqueta,
    required this.opciones,
    required this.valor,
    required this.alElegir,
    this.ayuda,
    super.key,
  });

  /// Rótulo que va encima de la lista, como el de un [Campo].
  final String etiqueta;
  final List<OpcionExcluyente<T>> opciones;

  /// El valor elegido, o `null` si todavía no se eligió ninguno. Puede ser una
  /// de las opciones aunque su valor sea `null` (p. ej. "Todos").
  final T? valor;

  /// Avisa la opción elegida. Con `null`, la lista queda deshabilitada.
  final ValueChanged<T>? alElegir;

  /// Texto de ayuda bajo la lista.
  final String? ayuda;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    final habilitada = alElegir != null;
    final color = habilitada ? c.tinta : c.tintaTenue;
    final esquina = BorderRadius.circular(Radios.control);
    // Se trabaja con el índice de la opción para que un valor `null` (por
    // ejemplo "Todos") sea una opción como cualquier otra.
    final indice = opciones.indexWhere((o) => o.valor == valor);

    return Semantics(
      container: true,
      label: etiqueta,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          ExcludeSemantics(child: EtiquetaDeCampo(etiqueta)),
          const SizedBox(height: Espacio.x2),
          DecoratedBox(
            decoration: BoxDecoration(
              color: c.hoja,
              borderRadius: esquina,
              border: Border.all(color: habilitada ? c.reglaFuerte : c.regla),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                isExpanded: true,
                value: indice == -1 ? null : indice,
                onChanged: habilitada
                    ? (i) {
                        if (i != null) alElegir!(opciones[i].valor);
                      }
                    : null,
                borderRadius: BorderRadius.circular(Radios.hoja),
                dropdownColor: c.hoja,
                menuMaxHeight: 360,
                padding: const EdgeInsets.symmetric(
                  horizontal: Espacio.x4,
                  vertical: Espacio.x1,
                ),
                icon: Icon(Icons.keyboard_arrow_down, color: color),
                style: textos.labelLarge!.copyWith(color: color),
                // Lo que se ve con la lista cerrada: solo la opción elegida.
                selectedItemBuilder: (context) => [
                  for (final opcion in opciones)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        opcion.etiqueta,
                        style: textos.labelLarge!.copyWith(color: color),
                      ),
                    ),
                ],
                items: [
                  for (var i = 0; i < opciones.length; i++)
                    DropdownMenuItem<int>(
                      value: i,
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(
                          minHeight: Espacio.objetivoTactil,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                opciones[i].etiqueta,
                                style: textos.labelLarge!.copyWith(
                                  color: c.tinta,
                                  fontWeight: i == indice
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                ),
                              ),
                            ),
                            if (i == indice)
                              Icon(Icons.check, size: 18, color: c.tinta),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          if (ayuda != null) ...[
            const SizedBox(height: Espacio.x2),
            Text(
              ayuda!,
              style: textos.bodySmall!.copyWith(color: c.tintaSuave),
            ),
          ],
        ],
      ),
    );
  }
}
