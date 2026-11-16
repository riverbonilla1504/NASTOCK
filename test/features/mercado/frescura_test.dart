import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/features/mercado/domain/mercado.dart';
import 'package:inversiones/features/mercado/presentation/frescura_provider.dart';
import 'package:inversiones/shared/widgets/tarjeta_de_cotizacion.dart';

import '../../core/realtime/falsos.dart';
import 'ayudas.dart';

void main() {
  test('RR-11 usa momento del proveedor y el límite configurado', () {
    final ahora = ahoraDePrueba;
    final vieja = Cotizacion(
      simbolo: 'QQQ',
      precio: 100,
      momento: ahora.subtract(const Duration(seconds: 61)),
      recibidoEn: ahora,
    );
    expect(
      cotizacionVigente(vieja, const Duration(seconds: 60), ahora),
      isFalse,
    );
    expect(
      cotizacionVigente(vieja, const Duration(seconds: 90), ahora),
      isTrue,
    );
    expect(
      cotizacionVigente(null, const Duration(seconds: 60), ahora),
      isFalse,
    );
    expect(cotizacionVigente(vieja, null, ahora), isFalse);
    expect(
      cotizacionVigente(vieja, const Duration(seconds: 61), ahora),
      isTrue,
      reason: 'RR-11 rechaza al superar el límite, no al igualarlo',
    );
  });

  testWidgets('CA-1 a CA-5: caduca sin eventos y se recupera por símbolo', (
    tester,
  ) async {
    final repo = MercadoRepositorioFalso();
    final fuente = FuenteFalsa();
    final tic = StreamController<int>();
    addTearDown(tic.close);
    var ahora = ahoraDePrueba;
    final contenedor = await abrirMercado(
      tester,
      overridesDeMercado(
        repo,
        fuente,
        tic: tic.stream,
        ahoraLocal: () => ahora,
      ),
    );

    expect(contenedor.read(cotizacionVigenteProvider('QQQ')), isTrue);
    ahora = ahora.add(const Duration(seconds: 61));
    tic.add(1);
    await asentar(tester);
    expect(contenedor.read(cotizacionVigenteProvider('QQQ')), isFalse);
    expect(
      tester
          .widgetList<FilaDeCotizacion>(find.byType(FilaDeCotizacion))
          .every((fila) => fila.desactualizado),
      isTrue,
    );

    // Recibir otra vez el mismo dato no rejuvenece el precio.
    fuente.crudo('mercado', 'cotizaciones', {
      'momento': ahora.toIso8601String(),
      'datos': [
        {'s': 'QQQ', 'p': 100, 'm': ahoraDePrueba.toIso8601String()},
      ],
    });
    await asentar(tester);
    expect(contenedor.read(cotizacionVigenteProvider('QQQ')), isFalse);

    fuente.crudo('mercado', 'cotizaciones', {
      'momento': ahora.toIso8601String(),
      'datos': [
        {'s': 'QQQ', 'p': 101, 'm': ahora.toIso8601String()},
      ],
    });
    await asentar(tester);
    expect(contenedor.read(cotizacionVigenteProvider('QQQ')), isTrue);
    expect(contenedor.read(cotizacionVigenteProvider('AAPL')), isFalse);
  });
}
