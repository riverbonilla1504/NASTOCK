import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:inversiones/app/catalogo/escena_mercado.dart';
import 'package:inversiones/app/catalogo/pagina_catalogo.dart';
import 'package:inversiones/app/catalogo/pagina_componentes.dart';
import 'package:inversiones/app/enrutador.dart';
import 'package:inversiones/app/pagina_inicio.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/core/configuracion/entorno.dart';
import 'package:inversiones/shared/widgets/selector_de_rango.dart';
import 'package:inversiones/shared/widgets/tarjeta_de_grafica.dart';
import 'package:inversiones/features/auth/data/ingreso_repositorio.dart';

import '../features/auth/falsos.dart';

const _entorno = Entorno(
  supabaseUrl: 'http://127.0.0.1:54321',
  supabaseLlavePublicable: 'llave-publicable-de-prueba',
);

Future<GoRouter> _abrir(
  WidgetTester tester, {
  required bool conCatalogo,
}) async {
  tester.view.physicalSize = const Size(400, 900);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final enrutador = crearEnrutador(conCatalogo: conCatalogo);
  addTearDown(enrutador.dispose);
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        entornoProvider.overrideWithValue(_entorno),
        // El cascarón de navegación lee la sesión: sin Supabase iniciado se
        // le da un repositorio sin sesión.
        ingresoRepositorioProvider.overrideWithValue(IngresoRepositorioFalso()),
      ],
      child: MaterialApp.router(theme: crearTema(), routerConfig: enrutador),
    ),
  );
  await tester.pumpAndSettle();
  return enrutador;
}

void main() {
  testWidgets('con permiso existen el catálogo, la escena y los componentes', (
    tester,
  ) async {
    final enrutador = await _abrir(tester, conCatalogo: true);

    enrutador.go(RutasCatalogo.inicio);
    await tester.pumpAndSettle();
    expect(find.byType(PaginaCatalogo), findsOneWidget);

    enrutador.go(RutasCatalogo.mercado);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(EscenaMercado), findsOneWidget);
    expect(tester.takeException(), isNull);

    enrutador.go(RutasCatalogo.componentes);
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.byType(PaginaComponentes), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('sin permiso la ruta del catálogo no existe (CA-10)', (
    tester,
  ) async {
    final enrutador = await _abrir(tester, conCatalogo: false);

    enrutador.go(RutasCatalogo.inicio);
    await tester.pumpAndSettle();
    expect(find.byType(PaginaCatalogo), findsNothing);
    // Una ruta que no existe lleva al inicio (HU-006, docs/03 §3); antes caía
    // en la página de error de go_router, que tampoco era el catálogo.
    expect(find.byType(PaginaInicio), findsOneWidget);
  });

  testWidgets('el catálogo cambia entre claro y oscuro', (tester) async {
    final enrutador = await _abrir(tester, conCatalogo: true);
    enrutador.go(RutasCatalogo.inicio);
    await tester.pumpAndSettle();

    Brightness brillo() =>
        Theme.of(tester.element(find.byType(PaginaCatalogo))).brightness;
    expect(brillo(), Brightness.light);
    await tester.tap(find.byTooltip('Ver en oscuro'));
    await tester.pumpAndSettle();
    expect(brillo(), Brightness.dark);
  });

  testWidgets('?tema=oscuro abre el catálogo en oscuro', (tester) async {
    final enrutador = await _abrir(tester, conCatalogo: true);
    enrutador.go('${RutasCatalogo.inicio}?tema=oscuro');
    await tester.pumpAndSettle();

    expect(
      Theme.of(tester.element(find.byType(PaginaCatalogo))).brightness,
      Brightness.dark,
    );
  });

  testWidgets('la pantalla de inicio enlaza el catálogo cuando existe', (
    tester,
  ) async {
    await _abrir(tester, conCatalogo: true);

    expect(find.text('Catálogo de componentes'), findsOneWidget);
    await tester.tap(find.text('Catálogo de componentes'));
    await tester.pumpAndSettle();
    expect(find.byType(PaginaCatalogo), findsOneWidget);
  });

  testWidgets('los componentes muestran la gráfica con su selector de rango', (
    tester,
  ) async {
    final enrutador = await _abrir(tester, conCatalogo: true);
    enrutador.go(RutasCatalogo.componentes);
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.byType(TarjetaDeGrafica),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.text('Valor del portafolio'), findsOneWidget);
    await tester.ensureVisible(find.byKey(claveDeRango(RangoDeGrafica.anio)));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(claveDeRango(RangoDeGrafica.anio)));
    await tester.pumpAndSettle();
    expect(
      tester.widget<TarjetaDeGrafica>(find.byType(TarjetaDeGrafica)).rango,
      RangoDeGrafica.anio,
    );
    expect(tester.takeException(), isNull);
  });
}
