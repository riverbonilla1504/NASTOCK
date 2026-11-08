import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/perfil/perfil.dart';
import 'package:inversiones/features/admin/usuarios/domain/invitacion.dart';
import 'package:inversiones/features/admin/usuarios/presentation/lista_de_invitaciones.dart';
import 'package:inversiones/shared/widgets/estados.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'ayudas.dart';

const _vigente = '00000000-0000-4000-8000-0000000000c1';

List<Invitacion> _unaDeCadaEstado() => [
  invitacion(
    id: _vigente,
    email: 'vigente@prueba.test',
    rol: RolApp.usuario,
    cupo: 250,
  ),
  invitacion(
    id: '00000000-0000-4000-8000-0000000000c2',
    email: 'pasada@prueba.test',
    rol: RolApp.analista,
    expiraEn: ahoraDePrueba.subtract(const Duration(hours: 2)),
  ),
  invitacion(
    id: '00000000-0000-4000-8000-0000000000c3',
    email: 'aceptada@prueba.test',
    estado: EstadoInvitacion.aceptada,
    aceptadaEn: DateTime.utc(2026, 11, 6, 16, 30),
  ),
  invitacion(
    id: '00000000-0000-4000-8000-0000000000c4',
    email: 'revocada@prueba.test',
    rol: RolApp.administrador,
    estado: EstadoInvitacion.revocada,
    revocadaEn: DateTime.utc(2026, 11, 7, 13),
  ),
  invitacion(
    id: '00000000-0000-4000-8000-0000000000c5',
    email: 'vencida@prueba.test',
    estado: EstadoInvitacion.vencida,
    expiraEn: DateTime.utc(2026, 11, 1, 15),
  ),
];

Finder _fila(String correo) =>
    find.ancestor(of: find.text(correo), matching: find.byType(Column)).first;

void main() {
  testWidgets('mientras carga muestra las líneas de carga', (tester) async {
    final espera = Completer<void>();
    await montarPantalla(tester, _Lento(espera.future), asentar: false);

    expect(find.byType(EstadoCargando), findsOneWidget);
    expect(find.text('Aún no hay invitaciones'), findsNothing);

    espera.complete();
    await tester.pumpAndSettle();
    expect(find.byType(EstadoCargando), findsNothing);
    expect(find.text('Aún no hay invitaciones'), findsOneWidget);
  });

  testWidgets('sin invitaciones dice qué pasará', (tester) async {
    await montarPantalla(tester, RepositorioFalso());

    expect(find.byKey(ListaDeInvitaciones.claveDelVacio), findsOneWidget);
    expect(find.text('Aún no hay invitaciones'), findsOneWidget);
    expect(
      find.text('Cuando invites a alguien aparecerá aquí con su estado.'),
      findsOneWidget,
    );
  });

  testWidgets('cada invitación muestra correo, rol, fecha y estado', (
    tester,
  ) async {
    await montarPantalla(
      tester,
      RepositorioFalso(invitaciones: _unaDeCadaEstado()),
    );

    expect(find.text('vigente@prueba.test'), findsOneWidget);
    expect(
      find.text(
        'Usuario · Cupo inicial USD 250,00 · Vence el 11/11/2026 10:00',
      ),
      findsOneWidget,
    );
    expect(find.text('Analista · Venció el 08/11/2026 08:00'), findsOneWidget);
    expect(
      find.text(
        'Usuario · Cupo inicial USD 0,00 · Aceptada el 06/11/2026 11:30',
      ),
      findsOneWidget,
    );
    expect(
      find.text('Administrador · Revocada el 07/11/2026 08:00'),
      findsOneWidget,
    );
    expect(
      find.text('Usuario · Cupo inicial USD 0,00 · Venció el 01/11/2026 10:00'),
      findsOneWidget,
    );
  });

  testWidgets('el estado se dice con palabra y forma, no solo con color', (
    tester,
  ) async {
    await montarPantalla(
      tester,
      RepositorioFalso(invitaciones: _unaDeCadaEstado()),
    );

    expect(find.text('Pendiente'), findsOneWidget);
    expect(find.text('Aceptada'), findsOneWidget);
    expect(find.text('Revocada'), findsOneWidget);
    // La pendiente con la fecha pasada y la guardada como vencida.
    expect(find.text('Vencida'), findsNWidgets(2));
  });

  testWidgets('el cupo inicial solo se muestra en un Usuario', (tester) async {
    await montarPantalla(
      tester,
      RepositorioFalso(
        invitaciones: [
          invitacion(rol: RolApp.analista, cupo: 999),
          invitacion(
            id: 'otro',
            email: 'otro@prueba.test',
            rol: RolApp.administrador,
            cupo: 999,
          ),
        ],
      ),
    );

    expect(find.textContaining('Cupo inicial USD'), findsNothing);
    expect(find.textContaining('999'), findsNothing);
  });

  testWidgets('solo la invitación vigente ofrece revocar', (tester) async {
    await montarPantalla(
      tester,
      RepositorioFalso(invitaciones: _unaDeCadaEstado()),
    );

    expect(find.text('Revocar'), findsOneWidget);
    expect(
      find.descendant(
        of: _fila('vigente@prueba.test'),
        matching: find.text('Revocar'),
      ),
      findsOneWidget,
    );
  });

  testWidgets('el botón de revocar nombra a la persona para el lector de '
      'pantalla', (tester) async {
    final semantica = tester.ensureSemantics();
    await montarPantalla(
      tester,
      RepositorioFalso(invitaciones: [invitacion(email: 'ana@prueba.test')]),
    );

    expect(
      find.bySemanticsLabel('Revocar la invitación de ana@prueba.test'),
      findsOneWidget,
    );
    semantica.dispose();
  });

  testWidgets('revocar pide confirmación y Cancelar no cambia nada', (
    tester,
  ) async {
    final repositorio = RepositorioFalso(
      invitaciones: [invitacion(id: _vigente, email: 'ana@prueba.test')],
    );
    await montarPantalla(tester, repositorio);

    await tester.tap(find.text('Revocar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Revocar la invitación?'), findsOneWidget);
    expect(
      find.textContaining('ana@prueba.test ya no podrá entrar con ella.'),
      findsOneWidget,
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(find.text('¿Revocar la invitación?'), findsNothing);
    expect(repositorio.revocadas, isEmpty);
    expect(find.text('Pendiente'), findsOneWidget);
  });

  testWidgets('confirmar revoca por la RPC, avisa y actualiza la lista', (
    tester,
  ) async {
    final repositorio = RepositorioFalso(
      invitaciones: [invitacion(id: _vigente, email: 'ana@prueba.test')],
    );
    await montarPantalla(tester, repositorio);

    await tester.tap(find.text('Revocar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Revocar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(repositorio.revocadas, [_vigente]);
    expect(
      find.text('Invitación revocada. ana@prueba.test ya no puede entrar.'),
      findsOneWidget,
    );
    expect(find.text('Revocada'), findsOneWidget);
    expect(find.text('Pendiente'), findsNothing);
    expect(find.text('Revocar'), findsNothing);
  });

  testWidgets('mientras revoca, el botón dice Procesando', (tester) async {
    final repositorio = RepositorioFalso(
      invitaciones: [invitacion(id: _vigente)],
    )..espera = Completer<void>();
    await montarPantalla(tester, repositorio);

    await tester.tap(find.text('Revocar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Revocar'),
      ),
    );
    await tester.pump();
    await tester.pump();

    expect(find.text('Procesando…'), findsOneWidget);

    repositorio.espera!.complete();
    await tester.pumpAndSettle();
    expect(find.text('Procesando…'), findsNothing);
  });

  testWidgets('si la invitación ya cambió de estado, muestra el mensaje y '
      'actualiza la lista', (tester) async {
    final repositorio =
        RepositorioFalso(invitaciones: [invitacion(id: _vigente)])
          ..errorAlRevocar = const PostgrestException(
            message: 'ESTADO_INVALIDO',
            code: 'P0001',
          );
    await montarPantalla(tester, repositorio);

    await tester.tap(find.text('Revocar'));
    await tester.pumpAndSettle();
    await tester.tap(
      find.descendant(
        of: find.byType(AlertDialog),
        matching: find.text('Revocar'),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.text('Esta operación ya cambió de estado. Actualiza la pantalla.'),
      findsOneWidget,
    );
    expect(repositorio.listados, 2);
  });

  testWidgets('si no se puede leer la lista, muestra el error y deja '
      'reintentar', (tester) async {
    final repositorio = RepositorioFalso()
      ..errorAlListar = Exception('sin red');
    await montarPantalla(tester, repositorio);

    expect(find.byKey(ListaDeInvitaciones.claveDelError), findsOneWidget);
    expect(
      find.text('Ocurrió un error inesperado. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.textContaining('sin red'), findsNothing);

    repositorio
      ..errorAlListar = null
      ..invitaciones = [invitacion(email: 'ana@prueba.test')];
    await tester.tap(find.text('Reintentar'));
    await tester.pumpAndSettle();

    expect(find.byKey(ListaDeInvitaciones.claveDelError), findsNothing);
    expect(find.text('ana@prueba.test'), findsOneWidget);
  });

  testWidgets('Actualizar vuelve a pedir la lista', (tester) async {
    final repositorio = RepositorioFalso();
    await montarPantalla(tester, repositorio);
    expect(find.text('Aún no hay invitaciones'), findsOneWidget);

    repositorio.invitaciones = [invitacion(email: 'nueva@prueba.test')];
    await tester.tap(find.text('Actualizar'));
    await tester.pumpAndSettle();

    expect(find.text('nueva@prueba.test'), findsOneWidget);
    expect(find.text('Aún no hay invitaciones'), findsNothing);
  });

  testWidgets('se ve sin desbordes en teléfono, con texto grande y en oscuro', (
    tester,
  ) async {
    tester.platformDispatcher.textScaleFactorTestValue = 1.6;
    addTearDown(tester.platformDispatcher.clearAllTestValues);
    await montarPantalla(
      tester,
      RepositorioFalso(invitaciones: _unaDeCadaEstado()),
      ancho: 360,
      alto: 800,
      oscuro: true,
    );

    // La lista queda debajo del formulario: se baja hasta verla.
    await tester.scrollUntilVisible(
      find.text('vigente@prueba.test'),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('vigente@prueba.test'), findsOneWidget);
  });
}

/// Un repositorio cuya primera lectura espera a [_espera].
class _Lento extends RepositorioFalso {
  _Lento(this._espera);

  final Future<void> _espera;

  @override
  Future<List<Invitacion>> listar() async {
    await _espera;
    return super.listar();
  }
}
