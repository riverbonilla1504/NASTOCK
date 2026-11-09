import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/cascaron_de_navegacion.dart';
import 'package:inversiones/app/destinos.dart';
import 'package:inversiones/app/rutas.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/core/perfil/perfil.dart';
import 'package:inversiones/core/realtime/estado_conexion.dart';
import 'package:inversiones/core/realtime/tiempo_real_provider.dart';
import 'package:inversiones/features/auth/presentation/acceso_de_sesion_provider.dart';
import 'package:inversiones/shared/widgets/barra_de_conexion.dart';
import 'package:inversiones/shared/widgets/barra_de_pestanas.dart';

/// La conexión en vivo fija en un estado, sin gestor ni sesión real.
class _ConexionFija extends ConexionNotifier {
  _ConexionFija(this._estado);
  final EstadoConexion _estado;

  @override
  EstadoConexion build() => _estado;
}

AccesoDeSesion _acceso(RolApp? rol) => AccesoDeSesion(
  haySesion: true,
  claims: ClaimsDeSesion(rol: rol, estado: EstadoCuenta.activo),
);

Future<List<String>> _abrir(
  WidgetTester tester, {
  required RolApp? rol,
  required double ancho,
  String ruta = Rutas.inicio,
  bool oscuro = false,
  double textoEscala = 1,
  EstadoConexion conexion = EstadoConexion.conectado,
  Widget hijo = const Center(child: Text('Contenido del destino')),
}) async {
  tester.view.physicalSize = Size(ancho, 800);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  final elegidas = <String>[];
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        accesoDeSesionProvider.overrideWithValue(_acceso(rol)),
        conexionProvider.overrideWith(() => _ConexionFija(conexion)),
      ],
      child: MaterialApp(
        theme: oscuro ? crearTemaOscuro() : crearTema(),
        builder: (context, hijo) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textoEscala)),
          child: hijo!,
        ),
        home: CascaronDeNavegacion(
          rutaActual: ruta,
          hijo: hijo,
          alElegirRuta: elegidas.add,
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return elegidas;
}

/// Las rutas de todos los destinos del MVP corto que están en pantalla.
List<String> _visibles(WidgetTester tester) => [
  for (final d in destinosDelMvp)
    if (find.byKey(claveDeDestino(d.ruta)).evaluate().isNotEmpty) d.ruta,
];

List<String> _menuDe(RolApp rol) =>
    destinosDeRol(rol).map((d) => d.ruta).toList();

void main() {
  for (final rol in RolApp.values) {
    group('menú de ${rol.name}', () {
      testWidgets('CA-1: en teléfono ve su isla y solo sus destinos', (
        tester,
      ) async {
        await _abrir(tester, rol: rol, ancho: 360);

        expect(find.byType(BarraDePestanas), findsOneWidget);
        expect(find.byType(NavigationRail), findsNothing);
        expect(_visibles(tester), _menuDe(rol));
        expect(find.text('Contenido del destino'), findsOneWidget);
      });

      testWidgets('CA-1: en ventana ancha ve el riel con los mismos destinos', (
        tester,
      ) async {
        await _abrir(tester, rol: rol, ancho: 1280);

        expect(find.byType(NavigationRail), findsOneWidget);
        expect(find.byType(BarraDePestanas), findsNothing);
        expect(_visibles(tester), _menuDe(rol));
        for (final d in destinosDeRol(rol)) {
          expect(find.text(d.etiqueta), findsOneWidget, reason: d.etiqueta);
        }
        expect(find.text('Contenido del destino'), findsOneWidget);
      });
    });
  }

  testWidgets('el Usuario ve Mi cupo y el Analista y el Administrador no', (
    tester,
  ) async {
    await _abrir(tester, rol: RolApp.usuario, ancho: 360);
    expect(find.byKey(claveDeDestino(Rutas.cupo)), findsOneWidget);
    expect(find.byKey(claveDeDestino(Rutas.admin)), findsNothing);

    await _abrir(tester, rol: RolApp.analista, ancho: 360);
    expect(find.byKey(claveDeDestino(Rutas.cupo)), findsNothing);
    expect(find.byKey(claveDeDestino(Rutas.admin)), findsNothing);

    await _abrir(tester, rol: RolApp.administrador, ancho: 360);
    expect(find.byKey(claveDeDestino(Rutas.cupo)), findsNothing);
    expect(find.byKey(claveDeDestino(Rutas.admin)), findsOneWidget);
  });

  testWidgets('sin rol solo queda Mercado', (tester) async {
    await _abrir(tester, rol: null, ancho: 360);

    expect(_visibles(tester), [Rutas.inicio]);
  });

  group('destino actual', () {
    testWidgets('la isla marca el destino de la ruta', (tester) async {
      await _abrir(
        tester,
        rol: RolApp.administrador,
        ancho: 360,
        ruta: Rutas.alertas,
      );

      expect(
        tester.widget<BarraDePestanas>(find.byType(BarraDePestanas)).actual,
        2,
      );
    });

    testWidgets('una subruta marca el destino de su ruta base', (tester) async {
      await _abrir(
        tester,
        rol: RolApp.administrador,
        ancho: 360,
        ruta: '/admin/usuarios',
      );

      expect(
        tester.widget<BarraDePestanas>(find.byType(BarraDePestanas)).actual,
        3,
      );
    });

    testWidgets('el riel marca el destino de la ruta', (tester) async {
      await _abrir(tester, rol: RolApp.usuario, ancho: 1280, ruta: Rutas.cupo);

      expect(
        tester
            .widget<NavigationRail>(find.byType(NavigationRail))
            .selectedIndex,
        2,
      );
    });
  });

  group('elegir un destino', () {
    testWidgets('en la isla avisa la ruta elegida', (tester) async {
      final elegidas = await _abrir(tester, rol: RolApp.usuario, ancho: 360);

      await tester.tap(find.byKey(claveDeDestino(Rutas.cupo)));
      await tester.pump();

      expect(elegidas, [Rutas.cupo]);
    });

    testWidgets('en el riel avisa la ruta elegida', (tester) async {
      final elegidas = await _abrir(
        tester,
        rol: RolApp.administrador,
        ancho: 1280,
      );

      await tester.tap(find.byKey(claveDeDestino(Rutas.admin)));
      await tester.pump();

      expect(elegidas, [Rutas.admin]);
    });

    testWidgets('tocar el destino actual no navega', (tester) async {
      final elegidas = await _abrir(tester, rol: RolApp.usuario, ancho: 360);

      await tester.tap(find.byKey(claveDeDestino(Rutas.inicio)));
      await tester.pump();

      expect(elegidas, isEmpty);
    });
  });

  group('conexión en vivo (FR-189)', () {
    for (final ancho in [360.0, 1280.0]) {
      testWidgets('a ${ancho.toInt()} dp reconectando muestra la barra', (
        tester,
      ) async {
        await _abrir(
          tester,
          rol: RolApp.usuario,
          ancho: ancho,
          conexion: EstadoConexion.reconectando,
        );

        expect(find.text('Reconectando…'), findsOneWidget);
        expect(find.text('Contenido del destino'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }

    testWidgets('sin conexión muestra la barra de sin conexión', (
      tester,
    ) async {
      await _abrir(
        tester,
        rol: RolApp.usuario,
        ancho: 360,
        conexion: EstadoConexion.sinConexion,
      );

      expect(find.text('Sin conexión'), findsOneWidget);
    });

    testWidgets('conectado no muestra ninguna barra', (tester) async {
      await _abrir(tester, rol: RolApp.usuario, ancho: 360);

      expect(find.byKey(ContenidoConConexion.claveDeLaBarra), findsNothing);
    });
  });

  group('se ve bien', () {
    for (final oscuro in [false, true]) {
      for (final ancho in [360.0, 1280.0]) {
        testWidgets(
          '${oscuro ? 'oscuro' : 'claro'} a ${ancho.toInt()} dp con el texto al doble',
          (tester) async {
            await _abrir(
              tester,
              rol: RolApp.administrador,
              ancho: ancho,
              oscuro: oscuro,
              textoEscala: 2,
            );

            expect(tester.takeException(), isNull);
            expect(_visibles(tester), _menuDe(RolApp.administrador));
          },
        );
      }
    }
  });

  group('la isla no tapa el contenido (D-69)', () {
    const claveDelUltimo = Key('ultimo-boton');
    final pagina = Scaffold(
      body: ListView(
        padding: const EdgeInsets.all(Espacio.x4),
        children: [
          for (var i = 0; i < 30; i++)
            SizedBox(height: 56, child: Text('Fila $i')),
          const FilledButton(
            key: claveDelUltimo,
            onPressed: null,
            child: Text('Invitar'),
          ),
        ],
      ),
    );

    for (final oscuro in [false, true]) {
      testWidgets('el último botón de una lista con scroll queda sobre la isla '
          '(${oscuro ? 'oscuro' : 'claro'})', (tester) async {
        await _abrir(
          tester,
          rol: RolApp.administrador,
          ancho: 360,
          oscuro: oscuro,
          hijo: pagina,
        );
        await tester.scrollUntilVisible(
          find.byKey(claveDelUltimo),
          200,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.drag(find.byType(ListView), const Offset(0, -2000));
        await tester.pumpAndSettle();

        final techoDeLaIsla = tester.getTopLeft(find.byType(BarraDePestanas));
        final boton = tester.getRect(find.byKey(claveDelUltimo));
        expect(boton.bottom, lessThanOrEqualTo(techoDeLaIsla.dy));
      });
    }

    testWidgets('el cuerpo termina donde empieza la isla', (tester) async {
      await _abrir(
        tester,
        rol: RolApp.usuario,
        ancho: 412,
        hijo: const SizedBox.expand(key: Key('cuerpo')),
      );

      final cuerpo = tester.getRect(find.byKey(const Key('cuerpo')));
      final techoDeLaIsla = tester.getTopLeft(find.byType(BarraDePestanas));
      expect(cuerpo.bottom, lessThanOrEqualTo(techoDeLaIsla.dy));
    });
  });
}
