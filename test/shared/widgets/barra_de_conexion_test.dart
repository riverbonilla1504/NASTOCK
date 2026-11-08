import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/realtime/estado_conexion.dart';
import 'package:inversiones/shared/widgets/barra_de_conexion.dart';

import 'montar.dart';

Widget _contenido(EstadoConexion estado) => SizedBox(
  height: 300,
  child: ContenidoConConexion(
    estado: estado,
    hijo: const Center(child: Text('Contenido')),
  ),
);

double _opacidad(WidgetTester tester) =>
    tester.widget<AnimatedOpacity>(find.byType(AnimatedOpacity)).opacity;

void main() {
  test('textoDeConexion: solo avisa cuando no está conectado', () {
    expect(textoDeConexion(EstadoConexion.conectado), isNull);
    expect(textoDeConexion(EstadoConexion.reconectando), 'Reconectando…');
    expect(textoDeConexion(EstadoConexion.sinConexion), 'Sin conexión');
  });

  testWidgets('conectado: sin barra y datos a plena opacidad', (tester) async {
    await montar(tester, _contenido(EstadoConexion.conectado));

    expect(find.byKey(ContenidoConConexion.claveDeLaBarra), findsNothing);
    expect(find.text('Contenido'), findsOneWidget);
    expect(_opacidad(tester), 1);
  });

  testWidgets('CA-4: reconectando muestra la barra y atenúa los datos', (
    tester,
  ) async {
    await montar(tester, _contenido(EstadoConexion.reconectando));

    expect(find.byKey(ContenidoConConexion.claveDeLaBarra), findsOneWidget);
    expect(find.text('Reconectando…'), findsOneWidget);
    expect(_opacidad(tester), opacidadReconectando);
  });

  testWidgets('CA-4: sin conexión muestra la barra y no atenúa los datos', (
    tester,
  ) async {
    await montar(tester, _contenido(EstadoConexion.sinConexion));

    expect(find.byKey(ContenidoConConexion.claveDeLaBarra), findsOneWidget);
    expect(find.text('Sin conexión'), findsOneWidget);
    expect(_opacidad(tester), 1);
  });

  testWidgets('el contenido conserva su estado al aparecer la barra', (
    tester,
  ) async {
    final clave = GlobalKey();
    Widget con(EstadoConexion estado) => SizedBox(
      height: 300,
      child: ContenidoConConexion(
        estado: estado,
        hijo: Text('Contenido', key: clave),
      ),
    );
    await montar(tester, con(EstadoConexion.conectado));
    final antes = tester.element(find.byKey(clave));

    await montar(tester, con(EstadoConexion.reconectando));
    await tester.pumpAndSettle();

    expect(tester.element(find.byKey(clave)), same(antes));
  });
}
