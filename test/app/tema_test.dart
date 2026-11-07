import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';

/// Contraste de WCAG entre dos colores opacos.
double contraste(Color a, Color b) {
  final la = a.computeLuminance();
  final lb = b.computeLuminance();
  final (claro, oscuro) = la > lb ? (la, lb) : (lb, la);
  return (claro + 0.05) / (oscuro + 0.05);
}

void main() {
  for (final (nombre, tema, colores, brillo) in [
    ('claro', crearTema(), ColoresAlmanaque.claro, Brightness.light),
    ('oscuro', crearTemaOscuro(), ColoresAlmanaque.oscuro, Brightness.dark),
  ]) {
    group('tema $nombre', () {
      test('trae los colores y la profundidad del Almanaque', () {
        expect(tema.brightness, brillo);
        expect(tema.extension<ColoresAlmanaque>(), colores);
        expect(tema.extension<ProfundidadAlmanaque>(), isNotNull);
        expect(tema.scaffoldBackgroundColor, colores.papel);
        expect(tema.colorScheme.primary, colores.tinta);
      });

      test('usa Archivo con cifras tabulares', () {
        final cuerpo = tema.textTheme.bodyMedium!;
        expect(cuerpo.fontFamily, Familias.texto);
        expect(cuerpo.fontFeatures, cifrasTabulares);
        expect(tema.textTheme.headlineMedium!.fontFamily, Familias.condensada);
      });

      test('el error no es rojo: se dibuja en tinta', () {
        expect(tema.colorScheme.error, colores.tinta);
      });

      test('cada par de texto cumple 4,5:1 (WCAG 2.2 AA)', () {
        final pares = {
          'tinta sobre hoja': (colores.tinta, colores.hoja),
          'tinta sobre papel': (colores.tinta, colores.papel),
          'tinta suave sobre hoja': (colores.tintaSuave, colores.hoja),
          'tinta suave sobre papel': (colores.tintaSuave, colores.papel),
          'tinta tenue sobre hoja': (colores.tintaTenue, colores.hoja),
          'tinta tenue sobre papel': (colores.tintaTenue, colores.papel),
          'morado sobre hoja': (colores.morado, colores.hoja),
          'alza sobre hoja': (colores.alza, colores.hoja),
          'baja sobre hoja': (colores.baja, colores.hoja),
          'texto sobre grafito': (colores.sobreGrafito, colores.grafito),
          'texto suave sobre grafito': (
            colores.sobreGrafitoSuave,
            colores.grafito,
          ),
          'morado sobre grafito': (colores.moradoSobreGrafito, colores.grafito),
          'texto sobre morado': (colores.sobreMorado, colores.morado),
          'tinta sobre morado tenue': (colores.tinta, colores.moradoTenue),
        };
        for (final MapEntry(key: par, value: (texto, fondo)) in pares.entries) {
          expect(
            contraste(texto, fondo),
            greaterThanOrEqualTo(4.5),
            reason: par,
          );
        }
      });

      test('el degradado de la barra conserva el contraste del texto', () {
        final degradado = tema.extension<ProfundidadAlmanaque>()!;
        for (final tono in degradado.degradadoGrafito.colors) {
          expect(
            contraste(colores.sobreGrafito, tono),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            contraste(colores.sobreGrafitoSuave, tono),
            greaterThanOrEqualTo(4.5),
          );
        }
      });
    });
  }
}
