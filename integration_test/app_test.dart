/// E2E de la app (docs/15 §2): abre la app real en Chrome contra el backend
/// local, entra con el ingreso con correo del modo pruebas y recorre la
/// navegación de cada rol. Cada historia agrega después sus escenarios del
/// catálogo de docs/15 §4 en este mismo directorio.
///
/// - **HU-005**: sin sesión la app abre en la pantalla de ingreso, conectada al
///   backend, y entrar con un usuario de la semilla lleva a la pantalla inicial.
/// - **E2E-01 (HU-006)**: cada rol ve su menú y las rutas de otro rol, o que no
///   existen, vuelven al inicio. La parte de backend (claims y RLS por rol) está
///   en `supabase/tests/e2e/01_ingreso_por_rol_test.ts`.
///
/// El ingreso con Google no se puede automatizar (docs/04 §1): por eso se usa el
/// de correo y contraseña, que solo existe con `MODO_PRUEBAS` (CI y local) y con
/// los usuarios de prueba de `supabase/seed.sql` (no son un secreto). Entre un rol
/// y otro la prueba cierra la sesión con `auth.signOut()`: cerrar sesión desde la
/// interfaz es de HU-007.
///
/// Se ejecuta con `flutter drive` (ver `scripts/verificar.sh`), que pasa
/// `MODO_PRUEBAS`, `SUPABASE_URL` y `SUPABASE_PUBLISHABLE_KEY` con `--dart-define`.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:integration_test/integration_test.dart';
import 'package:inversiones/app/cascaron_de_navegacion.dart';
import 'package:inversiones/app/enrutador.dart';
import 'package:inversiones/app/pagina_inicio.dart';
import 'package:inversiones/app/pagina_marcador.dart';
import 'package:inversiones/features/admin/presentation/pagina_administracion.dart';
import 'package:inversiones/features/auth/presentation/pagina_cuenta_suspendida.dart';
import 'package:inversiones/features/auth/presentation/pagina_de_ingreso.dart';
import 'package:inversiones/main.dart' as app;
import 'package:supabase_flutter/supabase_flutter.dart' show Supabase;

const _contrasenaDeLaSemilla = 'prueba-local-1234';

/// Todas las rutas con pestaña en el MVP corto.
const _todasLasPestanas = [
  Rutas.inicio,
  Rutas.oportunidades,
  Rutas.cupo,
  Rutas.alertas,
  Rutas.admin,
];

/// Lo que ve cada rol (docs/03 §3, MVP corto) y adónde no puede ir.
class _Rol {
  const _Rol(this.correo, this.menu, this.prohibidas);

  final String correo;
  final List<String> menu;
  final List<String> prohibidas;
}

const _roles = {
  'usuario': _Rol(
    'usuario1@prueba.local',
    [Rutas.inicio, Rutas.oportunidades, Rutas.cupo, Rutas.alertas],
    ['/admin', '/admin/usuarios', '/riesgo/bandeja', '/no-existe'],
  ),
  'analista': _Rol(
    'analista1@prueba.local',
    [Rutas.inicio, Rutas.oportunidades, Rutas.alertas],
    ['/admin', '/cupo', '/riesgo/bandeja', '/no-existe'],
  ),
  'administrador': _Rol(
    'admin@prueba.local',
    [Rutas.inicio, Rutas.oportunidades, Rutas.alertas, Rutas.admin],
    ['/cupo', '/riesgo/bandeja', '/no-existe'],
  ),
};

/// Espera, sin dormir a ciegas, a que aparezca algo que depende de la red.
Future<void> _esperarA(WidgetTester tester, Finder buscado) async {
  for (var i = 0; i < 40 && buscado.evaluate().isEmpty; i++) {
    await tester.pump(const Duration(milliseconds: 250));
  }
  await tester.pumpAndSettle();
}

Future<void> _ingresarConCorreo(WidgetTester tester, String correo) async {
  await tester.enterText(
    find.descendant(
      of: find.byKey(PaginaDeIngreso.claveDelCorreo),
      matching: find.byType(TextField),
    ),
    correo,
  );
  await tester.enterText(
    find.descendant(
      of: find.byKey(PaginaDeIngreso.claveDeLaContrasena),
      matching: find.byType(TextField),
    ),
    _contrasenaDeLaSemilla,
  );
  await tester.ensureVisible(find.byKey(PaginaDeIngreso.claveDelBotonDeCorreo));
  await tester.tap(find.byKey(PaginaDeIngreso.claveDelBotonDeCorreo));
  await _esperarA(tester, find.byType(PaginaInicio));
}

GoRouter _enrutador(WidgetTester tester) =>
    ProviderScope.containerOf(tester.element(find.byType(MaterialApp)))
        .read(enrutadorProvider);

String _ruta(GoRouter enrutador) =>
    enrutador.routeInformationProvider.value.uri.path;

List<String> _pestanasVisibles() => [
  for (final ruta in _todasLasPestanas)
    if (find.byKey(claveDeDestino(ruta)).evaluate().isNotEmpty) ruta,
];

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
    'la app abre en el ingreso y, por rol, cada uno ve su menú y las rutas de otro rol vuelven al inicio',
    (tester) async {
      await app.main();
      await tester.pumpAndSettle();

      // HU-005: sin sesión, la app abre en la pantalla de ingreso.
      expect(find.byType(PaginaDeIngreso), findsOneWidget);
      expect(find.byType(PaginaInicio), findsNothing);
      // Si faltaran los --dart-define, la pantalla avisaría que no hay conexión.
      expect(
        find.byKey(PaginaDeIngreso.claveDelAvisoDeConfiguracion),
        findsNothing,
      );
      // El ingreso con correo solo está con MODO_PRUEBAS.
      expect(
        find.byKey(PaginaDeIngreso.claveDelFormularioDePruebas),
        findsOneWidget,
      );

      for (final MapEntry(key: nombre, value: rol) in _roles.entries) {
        await _ingresarConCorreo(tester, rol.correo);

        // Con la sesión iniciada, la app pasa sola a la pantalla inicial.
        expect(find.byType(PaginaInicio), findsOneWidget, reason: nombre);
        expect(find.byType(PaginaDeIngreso), findsNothing, reason: nombre);
        expect(
          find.text('Plataforma de inversión asistida por IA'),
          findsOneWidget,
          reason: nombre,
        );
        expect(
          find.byKey(PaginaInicio.claveDeAvisoSinConfiguracion),
          findsNothing,
          reason: nombre,
        );

        // E2E-01 · CA-1: cada rol ve el menú de docs/03 §3 y ninguna pestaña más.
        expect(_pestanasVisibles(), rol.menu, reason: 'menú de $nombre');

        // Tocar una pestaña abre su pantalla (un marcador hasta que su historia
        // la construya).
        await tester.tap(find.byKey(claveDeDestino(Rutas.alertas)));
        await tester.pumpAndSettle();
        expect(_ruta(_enrutador(tester)), Rutas.alertas, reason: nombre);
        expect(find.byType(PaginaMarcador), findsOneWidget, reason: nombre);

        // E2E-01 · CA-2: las rutas de otro rol, o que no existen, vuelven al
        // inicio.
        final enrutador = _enrutador(tester);
        for (final prohibida in rol.prohibidas) {
          enrutador.go(prohibida);
          await tester.pumpAndSettle();
          expect(
            _ruta(enrutador),
            Rutas.inicio,
            reason: '$nombre en $prohibida',
          );
          expect(find.byType(PaginaInicio), findsOneWidget);
        }

        // El Administrador sí entra a Administración.
        if (rol.menu.contains(Rutas.admin)) {
          enrutador.go(Rutas.admin);
          await tester.pumpAndSettle();
          expect(_ruta(enrutador), Rutas.admin);
          expect(find.byType(PaginaAdministracion), findsOneWidget);
          expect(find.byKey(claveDeEntradaAInvitaciones), findsOneWidget);
        }

        // Cerrar la sesión (desde la prueba: la interfaz es de HU-007) lleva de
        // vuelta al ingreso.
        await Supabase.instance.client.auth.signOut();
        await _esperarA(tester, find.byType(PaginaDeIngreso));
        expect(find.byType(PaginaDeIngreso), findsOneWidget, reason: nombre);
      }

      // E2E-01 · CA-3: la cuenta suspendida de la semilla (perfil suspendido, sin
      // bloqueo en Auth: un token vigente cuyo estado ya cambió) llega a
      // /cuenta-suspendida, sin menú y sin poder abrir otra ruta.
      await tester.enterText(
        find.descendant(
          of: find.byKey(PaginaDeIngreso.claveDelCorreo),
          matching: find.byType(TextField),
        ),
        'suspendido@prueba.local',
      );
      await tester.enterText(
        find.descendant(
          of: find.byKey(PaginaDeIngreso.claveDeLaContrasena),
          matching: find.byType(TextField),
        ),
        _contrasenaDeLaSemilla,
      );
      await tester.ensureVisible(
        find.byKey(PaginaDeIngreso.claveDelBotonDeCorreo),
      );
      await tester.tap(find.byKey(PaginaDeIngreso.claveDelBotonDeCorreo));
      await _esperarA(tester, find.byType(PaginaCuentaSuspendida));

      expect(find.byType(PaginaCuentaSuspendida), findsOneWidget);
      expect(find.text(textoDeCuentaSuspendida), findsOneWidget);
      expect(_pestanasVisibles(), isEmpty);
      final enrutador = _enrutador(tester);
      expect(_ruta(enrutador), Rutas.cuentaSuspendida);
      for (final ruta in [Rutas.inicio, '/admin']) {
        enrutador.go(ruta);
        await tester.pumpAndSettle();
        expect(_ruta(enrutador), Rutas.cuentaSuspendida, reason: ruta);
      }

      // Su única salida es cerrar la sesión: vuelve al ingreso.
      await tester.tap(
        find.byKey(PaginaCuentaSuspendida.claveDelBotonDeCierre),
      );
      await _esperarA(tester, find.byType(PaginaDeIngreso));
      expect(find.byType(PaginaDeIngreso), findsOneWidget);
    },
  );
}
