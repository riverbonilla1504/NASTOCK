import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/perfil/perfil.dart';
import 'package:inversiones/features/admin/usuarios/presentation/formulario_de_invitacion.dart';
import 'package:inversiones/shared/widgets/botones.dart';
import 'package:inversiones/shared/widgets/lista_desplegable.dart';
import 'package:supabase_flutter/supabase_flutter.dart' show PostgrestException;

import 'ayudas.dart';

Finder get _correo => find.descendant(
  of: find.byKey(FormularioDeInvitacion.claveDelCorreo),
  matching: find.byType(TextField),
);

Finder get _cupo => find.descendant(
  of: find.byKey(FormularioDeInvitacion.claveDelCupo),
  matching: find.byType(TextField),
);

Finder get _invitar => find.widgetWithText(FilledButton, textoInvitar);

/// Abre la lista de roles con el rol [actual] y elige [nuevo].
Future<void> _elegirRol(
  WidgetTester tester,
  String actual,
  String nuevo,
) async {
  await tester.tap(find.text(actual));
  await tester.pumpAndSettle();
  await tester.tap(find.text(nuevo).last);
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('pide el correo, el rol y, para Usuario, el cupo inicial', (
    tester,
  ) async {
    await montarPantalla(tester, RepositorioFalso());

    expect(find.text('Invitar a una persona'), findsOneWidget);
    expect(find.text('Correo de Google'), findsOneWidget);
    expect(find.text('Rol'), findsOneWidget);
    // El rol es una lista desplegable: cerrada solo muestra el elegido y,
    // abierta, los tres roles.
    expect(find.byType(ListaDesplegable<RolApp>), findsOneWidget);
    expect(find.text('Usuario'), findsOneWidget);
    expect(find.text('Analista'), findsNothing);
    await tester.tap(find.text('Usuario'));
    await tester.pumpAndSettle();
    for (final rol in ['Usuario', 'Analista', 'Administrador']) {
      expect(find.text(rol), findsWidgets);
    }
    await tester.tap(find.text('Usuario').last);
    await tester.pumpAndSettle();
    expect(find.text('Analista'), findsNothing);
    expect(find.text('Cupo inicial (USD)'), findsOneWidget);
    expect(_invitar, findsOneWidget);
  });

  testWidgets('una ayuda fija dice que la app no envía correos y que el Gmail '
      'debe estar en los usuarios de prueba', (tester) async {
    await montarPantalla(tester, RepositorioFalso());

    expect(find.byKey(FormularioDeInvitacion.claveDeLaAyuda), findsOneWidget);
    expect(find.textContaining('La app no envía correos.'), findsOneWidget);
    expect(find.textContaining('usuarios de prueba de Google'), findsOneWidget);
  });

  testWidgets('el resultado de invitar se lleva a la vista en una pantalla '
      'corta', (tester) async {
    await montarPantalla(tester, RepositorioFalso(), ancho: 360, alto: 640);

    await tester.enterText(_correo, 'ana@gmail.com');
    await tester.ensureVisible(_invitar);
    await tester.pumpAndSettle();
    await tester.tap(_invitar);
    await tester.pumpAndSettle();

    final aviso = find.byKey(FormularioDeInvitacion.claveDelAvisoDeCreada);
    expect(aviso, findsOneWidget);
    final caja = tester.getRect(aviso);
    expect(caja.top, greaterThanOrEqualTo(0));
    expect(caja.bottom, lessThanOrEqualTo(640));
  });

  testWidgets('el cupo solo se pide al invitar a un Usuario', (tester) async {
    await montarPantalla(tester, RepositorioFalso());

    await _elegirRol(tester, 'Usuario', 'Analista');
    expect(find.text('Cupo inicial (USD)'), findsNothing);

    await _elegirRol(tester, 'Analista', 'Usuario');
    expect(find.text('Cupo inicial (USD)'), findsOneWidget);
  });

  testWidgets('no habla de cuentas corporativas ni de RiTech', (tester) async {
    await montarPantalla(tester, RepositorioFalso());

    final textos = tester
        .widgetList<Text>(find.byType(Text))
        .map((t) => (t.data ?? '').toLowerCase())
        .join('\n');
    expect(textos, isNot(contains('corporativ')));
    expect(textos, isNot(contains('ritech')));
  });

  testWidgets('un correo mal escrito no llama a la RPC y dice qué hacer', (
    tester,
  ) async {
    final repositorio = RepositorioFalso();
    await montarPantalla(tester, repositorio);

    for (final malo in ['', 'ana', 'ana@', 'ana@gmail', 'a na@gmail.com']) {
      await tester.enterText(_correo, malo);
      await tester.tap(_invitar);
      await tester.pumpAndSettle();

      expect(
        find.text('Escribe un correo como nombre@gmail.com.'),
        findsOneWidget,
        reason: 'con "$malo"',
      );
    }
    expect(repositorio.invitados, isEmpty);
  });

  testWidgets('el error del correo desaparece al corregirlo', (tester) async {
    await montarPantalla(tester, RepositorioFalso());

    await tester.tap(_invitar);
    await tester.pumpAndSettle();
    expect(
      find.text('Escribe un correo como nombre@gmail.com.'),
      findsOneWidget,
    );

    await tester.enterText(_correo, 'a');
    await tester.pumpAndSettle();
    expect(find.text('Escribe un correo como nombre@gmail.com.'), findsNothing);
  });

  testWidgets('un cupo que no es un monto no llama a la RPC', (tester) async {
    final repositorio = RepositorioFalso();
    await montarPantalla(tester, repositorio);

    await tester.enterText(_correo, 'ana@gmail.com');
    for (final malo in ['abc', '-5', '1.2.3', '12,345']) {
      await tester.enterText(_cupo, malo);
      await tester.tap(_invitar);
      await tester.pumpAndSettle();

      expect(
        find.text('Escribe un monto en USD, como 250 o 250,50.'),
        findsOneWidget,
        reason: 'con "$malo"',
      );
    }
    expect(repositorio.invitados, isEmpty);
  });

  testWidgets('invita, avisa que el sistema no envía correos y limpia el '
      'formulario', (tester) async {
    final repositorio = RepositorioFalso();
    await montarPantalla(tester, repositorio);

    await tester.enterText(_correo, '  Ana@Gmail.com ');
    await tester.enterText(_cupo, '250,5');
    await tester.tap(_invitar);
    await tester.pumpAndSettle();

    expect(repositorio.invitados, [
      (email: 'Ana@Gmail.com', rol: RolApp.usuario, cupo: 250.5),
    ]);
    expect(
      find.byKey(FormularioDeInvitacion.claveDelAvisoDeCreada),
      findsOneWidget,
    );
    expect(find.text('Invitación creada'), findsOneWidget);
    expect(
      find.text(
        'Invitación creada para ana@gmail.com como Usuario. La app no envía '
        'correos: avísale que entre con Google con ese Gmail antes del '
        '15/11/2026 10:00.',
      ),
      findsOneWidget,
    );
    expect(tester.widget<TextField>(_correo).controller!.text, isEmpty);
    expect(tester.widget<TextField>(_cupo).controller!.text, isEmpty);
    // La lista se volvió a pedir y muestra la invitación nueva.
    expect(repositorio.listados, 2);
  });

  testWidgets('un cupo vacío se envía como 0', (tester) async {
    final repositorio = RepositorioFalso();
    await montarPantalla(tester, repositorio);

    await tester.enterText(_correo, 'ana@gmail.com');
    await tester.tap(_invitar);
    await tester.pumpAndSettle();

    expect(repositorio.invitados.single.cupo, 0);
  });

  testWidgets('con un rol distinto de Usuario el cupo se envía en 0 aunque '
      'se hubiera escrito', (tester) async {
    final repositorio = RepositorioFalso();
    await montarPantalla(tester, repositorio);

    await tester.enterText(_correo, 'ana@gmail.com');
    await tester.enterText(_cupo, '500');
    await _elegirRol(tester, 'Usuario', 'Analista');
    await tester.tap(_invitar);
    await tester.pumpAndSettle();

    expect(repositorio.invitados.single.rol, RolApp.analista);
    expect(repositorio.invitados.single.cupo, 0);
  });

  testWidgets('mientras envía, el botón dice Procesando y no se repite', (
    tester,
  ) async {
    final repositorio = RepositorioFalso()..espera = Completer<void>();
    await montarPantalla(tester, repositorio);

    await tester.enterText(_correo, 'ana@gmail.com');
    await tester.tap(_invitar);
    await tester.pump();

    expect(find.text(textoProcesando), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    repositorio.espera!.complete();
    await tester.pumpAndSettle();
    expect(find.text(textoProcesando), findsNothing);
    expect(repositorio.invitados, hasLength(1));
  });

  for (final (codigo, mensaje) in [
    (
      'INVITACION_DUPLICADA',
      'Ya existe una invitación vigente para ese correo.',
    ),
    ('CORREO_YA_REGISTRADO', 'Ese correo ya tiene una cuenta.'),
    ('NO_AUTORIZADO', 'No tienes permiso para esta acción.'),
    ('SESION_INVALIDA', 'Tu sesión no es válida. Vuelve a ingresar.'),
  ]) {
    testWidgets('el código $codigo se muestra con su mensaje', (tester) async {
      final repositorio = RepositorioFalso()
        ..errorAlInvitar = PostgrestException(message: codigo, code: 'P0001');
      await montarPantalla(tester, repositorio);

      await tester.enterText(_correo, 'ana@gmail.com');
      await tester.tap(_invitar);
      await tester.pumpAndSettle();

      expect(find.text(mensaje), findsOneWidget);
      expect(find.text('Invitación creada'), findsNothing);
      // El correo escrito se conserva para corregirlo, y el botón vuelve.
      expect(
        tester.widget<TextField>(_correo).controller!.text,
        'ana@gmail.com',
      );
      expect(
        tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
        isNotNull,
      );
    });
  }

  testWidgets('un error desconocido nunca muestra su texto crudo', (
    tester,
  ) async {
    final repositorio = RepositorioFalso()
      ..errorAlInvitar = Exception('duplicate key value violates unique');
    await montarPantalla(tester, repositorio);

    await tester.enterText(_correo, 'ana@gmail.com');
    await tester.tap(_invitar);
    await tester.pumpAndSettle();

    expect(
      find.text('Ocurrió un error inesperado. Inténtalo de nuevo.'),
      findsOneWidget,
    );
    expect(find.textContaining('duplicate key'), findsNothing);
  });

  testWidgets('el aviso de creada se quita al empezar a escribir otra', (
    tester,
  ) async {
    await montarPantalla(tester, RepositorioFalso());

    await tester.enterText(_correo, 'ana@gmail.com');
    await tester.tap(_invitar);
    await tester.pumpAndSettle();
    expect(find.text('Invitación creada'), findsOneWidget);

    await tester.enterText(_correo, 'l');
    await tester.pumpAndSettle();
    expect(find.text('Invitación creada'), findsNothing);
  });

  testWidgets('un aviso de creada se quita al intentar otra invitación', (
    tester,
  ) async {
    final repositorio = RepositorioFalso();
    await montarPantalla(tester, repositorio);

    await tester.enterText(_correo, 'ana@gmail.com');
    await tester.tap(_invitar);
    await tester.pumpAndSettle();
    expect(find.text('Invitación creada'), findsOneWidget);

    repositorio.errorAlInvitar = const PostgrestException(
      message: 'INVITACION_DUPLICADA',
      code: 'P0001',
    );
    await tester.enterText(_correo, 'ana@gmail.com');
    await tester.tap(_invitar);
    await tester.pumpAndSettle();

    expect(find.text('Invitación creada'), findsNothing);
    expect(
      find.text('Ya existe una invitación vigente para ese correo.'),
      findsOneWidget,
    );
  });
}
