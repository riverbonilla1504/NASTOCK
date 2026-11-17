import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/shared/widgets/boton_de_google.dart';
import 'package:inversiones/shared/widgets/botones.dart';

Future<void> _montar(WidgetTester tester, Widget boton, {ThemeData? tema}) =>
    tester.pumpWidget(
      MaterialApp(
        theme: tema ?? crearTema(),
        home: Scaffold(body: Center(child: boton)),
      ),
    );

ButtonStyle _estilo(WidgetTester tester) =>
    tester.widget<OutlinedButton>(find.byType(OutlinedButton)).style!;

void main() {
  test('los trazos de la G caben en su lienzo de 48 × 48', () {
    final rojo = trazoDeSvg(
      'M24 9.5c3.54 0 6.71 1.22 9.21 3.6l6.85-6.85C35.9 2.38 30.47 0 24 0 '
      '14.62 0 6.51 5.38 2.56 13.22l7.98 6.19C12.43 13.72 17.74 9.5 24 9.5z',
    ).getBounds();
    expect(rojo.left, closeTo(2.56, 0.01));
    expect(rojo.top, closeTo(0, 0.01));
    expect(rojo.right, closeTo(40.06, 0.01));
    expect(rojo.bottom, closeTo(19.41, 0.01));

    // La S refleja el control anterior: el amarillo es simétrico en y = 24.
    final amarillo = trazoDeSvg(
      'M10.53 28.59c-.48-1.45-.76-2.99-.76-4.59s.27-3.14.76-4.59l-7.98-6.19'
      'C.92 16.46 0 20.12 0 24c0 3.88.92 7.54 2.56 10.78l7.97-6.19z',
    ).getBounds();
    expect(amarillo.left, closeTo(0, 0.01));
    expect(amarillo.right, closeTo(10.53, 0.01));
    expect(amarillo.top, closeTo(13.22, 0.01));
    expect(amarillo.bottom, closeTo(34.78, 0.01));
  });

  testWidgets('blanco con borde gris y la G a la izquierda del texto', (
    tester,
  ) async {
    await _montar(
      tester,
      BotonDeGoogle(texto: 'Entrar con Google', alPresionar: () {}),
    );

    final estilo = _estilo(tester);
    expect(estilo.backgroundColor!.resolve({}), MarcaGoogle.fondoClaro);
    expect(estilo.side!.resolve({})!.color, MarcaGoogle.bordeClaro);
    expect(estilo.foregroundColor!.resolve({}), MarcaGoogle.textoClaro);
    expect(
      tester.getCenter(find.byType(LogoDeGoogle)).dx,
      lessThan(tester.getTopLeft(find.text('Entrar con Google')).dx),
    );
    expect(tester.getSize(find.byType(LogoDeGoogle)), const Size.square(18));
    expect(
      tester.getSize(find.byType(OutlinedButton)).height,
      greaterThanOrEqualTo(Espacio.objetivoTactil),
    );
  });

  testWidgets('en el tema oscuro usa el botón oscuro de Google', (
    tester,
  ) async {
    await _montar(
      tester,
      BotonDeGoogle(texto: 'Entrar con Google', alPresionar: () {}),
      tema: crearTemaOscuro(),
    );

    expect(
      _estilo(tester).backgroundColor!.resolve({}),
      MarcaGoogle.fondoOscuro,
    );
  });

  testWidgets('mientras se envía dice Procesando… y no se puede tocar', (
    tester,
  ) async {
    var toques = 0;
    await _montar(
      tester,
      BotonDeGoogle(
        texto: 'Entrar con Google',
        enviando: true,
        alPresionar: () => toques++,
      ),
    );

    expect(find.text(textoProcesando), findsOneWidget);
    expect(find.text('Entrar con Google'), findsNothing);
    await tester.tap(find.byType(OutlinedButton));
    expect(toques, 0);
  });

  testWidgets('deshabilitado atenúa la G', (tester) async {
    await _montar(
      tester,
      const BotonDeGoogle(texto: 'Entrar con Google', alPresionar: null),
    );

    final opacidad = tester.widget<Opacity>(
      find.ancestor(
        of: find.byType(LogoDeGoogle),
        matching: find.byType(Opacity),
      ),
    );
    expect(opacidad.opacity, 0.38);
  });
}
