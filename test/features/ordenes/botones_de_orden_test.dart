import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/core/perfil/perfil.dart';
import 'package:inversiones/core/perfil/perfil_provider.dart';
import 'package:inversiones/features/ordenes/data/ordenes_repositorio.dart';
import 'package:inversiones/features/ordenes/domain/orden_manual.dart';
import 'package:inversiones/features/ordenes/presentation/botones_de_orden.dart';
import 'package:inversiones/features/mercado/presentation/frescura_provider.dart';
import 'package:inversiones/shared/widgets/botones.dart';

class _Vigencia extends Notifier<bool> {
  @override
  bool build() => true;

  void cambiar(bool valor) => state = valor;
}

final _vigencia = NotifierProvider<_Vigencia, bool>(_Vigencia.new);

class _RepoFalso implements OrdenesRepositorio {
  final List<Map<String, Object?>> llamadas = [];

  @override
  Future<ProteccionPorDefecto> proteccionPorDefecto() async =>
      ProteccionPorDefecto.predeterminada;

  @override
  Future<void> crearOrdenManual({
    required String id,
    required String simbolo,
    required LadoDeOrden lado,
    required int cantidad,
    double? stopPct,
    double? objetivoPct,
  }) async {
    llamadas.add({
      'id': id,
      'simbolo': simbolo,
      'lado': lado.valor,
      'cantidad': cantidad,
      'stop': stopPct,
      'objetivo': objetivoPct,
    });
  }
}

Perfil _perfil(RolApp rol) => Perfil(
  id: 'u1',
  email: 'u@prueba.test',
  nombre: 'U',
  rol: rol,
  estado: EstadoCuenta.activo,
  recibeSugerencias: false,
  version: 1,
);

Future<ProviderContainer> _montar(
  WidgetTester t,
  RolApp rol,
  _RepoFalso repo,
) async {
  t.view.physicalSize = const Size(360, 1200);
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(
    ProviderScope(
      overrides: [
        cotizacionVigenteProvider.overrideWith(
          (ref, simbolo) => ref.watch(_vigencia),
        ),
        perfilProvider.overrideWith(
          (ref) async => PerfilDeSesion(
            claims: ClaimsDeSesion(rol: rol, estado: EstadoCuenta.activo),
            fila: _perfil(rol),
          ),
        ),
        ordenesRepositorioProvider.overrideWithValue(repo),
      ],
      child: MaterialApp(
        theme: crearTema(),
        home: const Scaffold(body: BotonesDeOrden(simbolo: 'QQQ', precio: 100)),
      ),
    ),
  );
  await t.pumpAndSettle();
  return ProviderScope.containerOf(t.element(find.byType(BotonesDeOrden)));
}

void main() {
  testWidgets('HU-032: una compra caduca también dentro de la confirmación', (
    t,
  ) async {
    final repo = _RepoFalso();
    final contenedor = await _montar(t, RolApp.usuario, repo);
    void vigente(bool valor) =>
        contenedor.read(_vigencia.notifier).cambiar(valor);
    BotonPrimario boton(String texto) => t.widget<BotonPrimario>(
      find.byWidgetPredicate((w) => w is BotonPrimario && w.texto == texto),
    );

    vigente(false);
    await t.pumpAndSettle();
    expect(boton('Comprar').alPresionar, isNull);
    expect(
      t.widget<BotonSecundario>(find.byType(BotonSecundario)).alPresionar,
      isNotNull,
    );
    vigente(true);
    await t.pumpAndSettle();
    await t.tap(find.text('Comprar'));
    await t.pumpAndSettle();
    await t.enterText(find.byType(TextField).first, '2');

    vigente(false);
    await t.pumpAndSettle();
    expect(boton('Revisar orden').alPresionar, isNull);
    expect(repo.llamadas, isEmpty);
    vigente(true);
    await t.pumpAndSettle();
    await t.tap(find.text('Revisar orden'));
    await t.pumpAndSettle();

    vigente(false);
    await t.pumpAndSettle();
    expect(boton('Confirmar').alPresionar, isNull);
    expect(repo.llamadas, isEmpty);
    vigente(true);
    await t.pumpAndSettle();
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();
    expect(repo.llamadas, hasLength(1));
  });

  testWidgets('CA-6: un analista no ve Comprar ni Vender', (t) async {
    await _montar(t, RolApp.analista, _RepoFalso());
    expect(find.text('Comprar'), findsNothing);
    expect(find.text('Vender'), findsNothing);
  });

  testWidgets('CA-1/CA-2: el Usuario compra con stop y objetivo precargados', (
    t,
  ) async {
    final repo = _RepoFalso();
    await _montar(t, RolApp.usuario, repo);
    await t.tap(find.text('Comprar'));
    await t.pumpAndSettle();
    expect(find.text('8'), findsOneWidget);
    expect(find.text('15'), findsOneWidget);

    await t.tap(find.text('Revisar orden'));
    await t.pumpAndSettle();
    expect(find.textContaining('número entero'), findsOneWidget);
    expect(repo.llamadas, isEmpty);

    await t.enterText(find.byType(TextField).first, '4');
    await t.tap(find.text('Revisar orden'));
    await t.pumpAndSettle();
    expect(find.text('Confirmar'), findsOneWidget);
    await t.tap(find.text('Confirmar'));
    await t.pumpAndSettle();

    expect(repo.llamadas, hasLength(1));
    expect(repo.llamadas.single['cantidad'], 4);
    expect(repo.llamadas.single['lado'], 'compra');
    expect(repo.llamadas.single['stop'], 8);
    expect(repo.llamadas.single['objetivo'], 15);
    expect(find.textContaining('enviada'), findsOneWidget);
  });
}
