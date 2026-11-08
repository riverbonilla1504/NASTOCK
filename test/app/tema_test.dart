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
    ('claro', crearTema(), ColoresTema.claro, Brightness.light),
    ('oscuro', crearTemaOscuro(), ColoresTema.oscuro, Brightness.dark),
  ]) {
    group('tema $nombre', () {
      test('trae los colores y la profundidad del sistema', () {
        expect(tema.brightness, brillo);
        expect(tema.extension<ColoresTema>(), colores);
        expect(tema.extension<ProfundidadTema>(), isNotNull);
        expect(tema.scaffoldBackgroundColor, colores.papel);
        expect(tema.colorScheme.primary, colores.morado);
      });

      test('usa Inter para el texto y JetBrains Mono para las cifras', () {
        final cuerpo = tema.textTheme.bodyMedium!;
        expect(cuerpo.fontFamily, Familias.texto);
        expect(cuerpo.fontFeatures, cifrasTabulares);
        expect(tema.textTheme.headlineMedium!.fontFamily, Familias.texto);
        expect(tema.textTheme.displaySmall!.fontFamily, Familias.cifras);
        final cifra = estiloDeCifra(cuerpo);
        expect(cifra.fontFamily, Familias.cifras);
        expect(cifra.fontFeatures, cifrasTabulares);
      });

      test('el botón principal va en el acento y la tarjeta tiene 8 dp', () {
        final fondo = tema.filledButtonTheme.style!.backgroundColor!
            .resolve(<WidgetState>{});
        expect(fondo, colores.morado);
        final forma = tema.cardTheme.shape! as RoundedRectangleBorder;
        expect(forma.borderRadius, BorderRadius.circular(Radios.hoja));
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
          'texto sobre morado': (colores.sobreMorado, colores.morado),
          'tinta sobre morado tenue': (colores.tinta, colores.moradoTenue),
          'morado sobre morado tenue': (colores.morado, colores.moradoTenue),
          'tinta sobre relleno': (colores.tinta, colores.relleno),
          'tinta tenue sobre relleno': (colores.tintaTenue, colores.relleno),
        };
        for (final MapEntry(key: par, value: (texto, fondo)) in pares.entries) {
          expect(
            contraste(texto, fondo),
            greaterThanOrEqualTo(4.5),
            reason: par,
          );
        }
      });

      test('el borde de un campo y el acento cumplen 3:1 (WCAG 1.4.11)', () {
        expect(
          contraste(colores.reglaFuerte, colores.hoja),
          greaterThanOrEqualTo(3),
          reason: 'borde de campo sobre hoja',
        );
        expect(
          contraste(colores.morado, colores.hoja),
          greaterThanOrEqualTo(3),
          reason: 'línea de gráfica sobre hoja',
        );
        expect(
          contraste(colores.morado, colores.papel),
          greaterThanOrEqualTo(4.5),
          reason: 'botón de texto sobre papel',
        );
      });
    });
  }
}
