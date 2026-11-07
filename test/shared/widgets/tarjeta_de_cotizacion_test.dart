import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/shared/widgets/botones.dart';
import 'package:inversiones/shared/widgets/cifras.dart';
import 'package:inversiones/shared/widgets/grafica_de_linea.dart';
import 'package:inversiones/shared/widgets/tarjeta_de_cotizacion.dart';

import 'montar.dart';

void main() {
  testWidgets('muestra símbolo, precio, variación, antigüedad y curva', (
    tester,
  ) async {
    await montar(
      tester,
      TarjetaDeCotizacion(
        simbolo: 'QLD',
        nombre: 'ProShares Ultra QQQ · ×2',
        precio: 98.14,
        variacion: 2.47,
        antiguedad: const Duration(seconds: 8),
        curva: const [95.78, 97.1, 98.14],
        ahora: 0.35,
        etiquetasDelEje: const ['09:30', 'ahora 11:46', '16:00'],
        acciones: [BotonPrimario(texto: 'Comprar', alPresionar: () {})],
      ),
    );

    expect(find.text('QLD'), findsOneWidget);
    expect(find.text('USD 98,14'), findsOneWidget);
    expect(find.text('+2,47 %'), findsOneWidget);
    expect(find.text('hace 8 s'), findsOneWidget);
    expect(find.byType(GraficaDeLinea), findsOneWidget);
    expect(find.text('ahora 11:46'), findsOneWidget);
    expect(find.text('Comprar'), findsOneWidget);
  });

  testWidgets('desactualizada marca la cifra y la antigüedad', (tester) async {
    await montar(
      tester,
      const TarjetaDeCotizacion(
        simbolo: 'AAPL',
        nombre: 'Apple',
        precio: 231.08,
        variacion: -0.82,
        antiguedad: Duration(minutes: 2),
        desactualizado: true,
      ),
    );

    expect(
      tester.widget<CifraUsd>(find.byType(CifraUsd)).desactualizada,
      isTrue,
    );
    expect(find.text('desactualizado · 2 min'), findsOneWidget);
    expect(find.byType(GraficaDeLinea), findsNothing);
  });

  testWidgets('la fila compacta cabe en una lista densa', (tester) async {
    var toques = 0;
    await montar(
      tester,
      FilaDeCotizacion(
        simbolo: 'QQQ',
        nombre: 'Invesco QQQ Trust · ×1',
        precio: 512.36,
        variacion: 1.24,
        antiguedad: const Duration(seconds: 8),
        alTocar: () => toques++,
      ),
    );

    expect(find.text('USD 512,36'), findsOneWidget);
    expect(find.text('8 s'), findsOneWidget);
    expect(
      tester.getSize(find.byType(FilaDeCotizacion)).height,
      greaterThanOrEqualTo(48),
    );
    await tester.tap(find.text('QQQ'));
    expect(toques, 1);
  });
}
