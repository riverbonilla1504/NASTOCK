import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/shared/widgets/cifras.dart';

import 'montar.dart';

void main() {
  testWidgets('el monto va en USD con dos decimales y cifras tabulares', (
    tester,
  ) async {
    await montar(tester, const CifraUsd(10000, tamano: TamanoCifra.grande));

    final texto = tester.widget<Text>(find.text('USD 10.000,00'));
    expect(texto.style!.fontFeatures, cifrasTabulares);
  });

  testWidgets('un precio desactualizado se subraya punteado y lo dice', (
    tester,
  ) async {
    final semantica = tester.ensureSemantics();
    await montar(tester, const CifraUsd(231.08, desactualizada: true));

    final texto = tester.widget<Text>(find.text('USD 231,08'));
    expect(texto.style!.decorationStyle, TextDecorationStyle.dotted);
    expect(
      find.bySemanticsLabel('USD 231,08, precio desactualizado'),
      findsOneWidget,
    );
    semantica.dispose();
  });

  testWidgets('la variación lleva flecha, signo y color de dirección', (
    tester,
  ) async {
    await montar(
      tester,
      const Column(children: [Variacion(2.47), Variacion(-0.82), Variacion(0)]),
    );

    expect(find.text('+2,47 %'), findsOneWidget);
    expect(find.text('-0,82 %'), findsOneWidget);
    expect(find.text('0,00 %'), findsOneWidget);
    expect(find.byIcon(Icons.arrow_upward), findsOneWidget);
    expect(find.byIcon(Icons.arrow_downward), findsOneWidget);
    expect(find.byIcon(Icons.remove), findsOneWidget);
    final sube = tester.widget<Text>(find.text('+2,47 %'));
    final baja = tester.widget<Text>(find.text('-0,82 %'));
    expect(sube.style!.color, ColoresTema.claro.alza);
    expect(baja.style!.color, ColoresTema.claro.baja);
  });

  testWidgets('la variación se lee en palabras', (tester) async {
    final semantica = tester.ensureSemantics();
    await montar(tester, const Variacion(-0.82));

    expect(find.bySemanticsLabel('Baja 0,82 %'), findsOneWidget);
    semantica.dispose();
  });

  testWidgets('la antigüedad dice hace cuánto y si está desactualizada', (
    tester,
  ) async {
    await montar(
      tester,
      const Column(
        children: [
          AntiguedadDelDato(Duration(seconds: 8)),
          AntiguedadDelDato(Duration(seconds: 9), compacta: true),
          AntiguedadDelDato(Duration(minutes: 2), desactualizado: true),
        ],
      ),
    );

    expect(find.text('hace 8 s'), findsOneWidget);
    expect(find.text('9 s'), findsOneWidget);
    expect(find.text('desactualizado · 2 min'), findsOneWidget);
  });
}
