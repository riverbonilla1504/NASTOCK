import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/errores/codigos_de_error.dart';
import 'package:inversiones/core/errores/traduccion_de_errores.dart';
import 'package:inversiones/core/formato/formato_dinero.dart';
import 'package:inversiones/shared/widgets/botones.dart';
import 'package:inversiones/shared/widgets/dialogo_de_confirmacion.dart';

import 'montar.dart';

void main() {
  group('ControladorDeConfirmacion (estados de docs/08 §9.3)', () {
    test('arranca inactivo y al abrir pasa a confirmando', () {
      final c = ControladorDeConfirmacion();
      expect(c.estado, EstadoDeConfirmacion.inactivo);

      c.abrir();
      expect(c.estado, EstadoDeConfirmacion.confirmando);
    });

    test('confirmar pasa por enviando y termina en hecho', () async {
      final c = ControladorDeConfirmacion()..abrir();
      final respuesta = Completer<void>();
      final estados = <EstadoDeConfirmacion>[];
      c.addListener(() => estados.add(c.estado));

      final envio = c.confirmar(() => respuesta.future);
      expect(c.estado, EstadoDeConfirmacion.enviando);
      expect(c.enviando, isTrue);

      respuesta.complete();
      await envio;
      expect(estados, [
        EstadoDeConfirmacion.enviando,
        EstadoDeConfirmacion.hecho,
      ]);
    });

    test(
      'si la acción falla queda en error con su causa y deja reintentar',
      () async {
        final c = ControladorDeConfirmacion()..abrir();
        var intento = 0;
        Future<void> accion() async {
          if (++intento == 1) throw const ErrorDeNegocio('MERCADO_CERRADO');
        }

        await c.confirmar(accion);
        expect(c.estado, EstadoDeConfirmacion.error);
        expect(c.error, isA<ErrorDeNegocio>());

        await c.confirmar(accion);
        expect(c.estado, EstadoDeConfirmacion.hecho);
        expect(c.error, isNull);
      },
    );

    test('cancelar pasa a cancelado', () {
      final c = ControladorDeConfirmacion()..abrir();

      c.cancelar();
      expect(c.estado, EstadoDeConfirmacion.cancelado);
    });

    test(
      'mientras se envía no se puede cancelar ni confirmar otra vez',
      () async {
        final c = ControladorDeConfirmacion()..abrir();
        final respuesta = Completer<void>();
        var llamadas = 0;

        final envio = c.confirmar(() {
          llamadas++;
          return respuesta.future;
        });
        c.cancelar();
        await c.confirmar(() async => llamadas++);

        expect(c.estado, EstadoDeConfirmacion.enviando);
        expect(llamadas, 1);
        respuesta.complete();
        await envio;
        expect(c.estado, EstadoDeConfirmacion.hecho);
      },
    );
  });

  group('confirmarAccion', () {
    Future<void> abrirDialogo(WidgetTester tester) async {
      await tester.tap(find.text('Abrir'));
      await tester.pumpAndSettle();
    }

    Future<void> montarConBoton(
      WidgetTester tester,
      Future<void> Function() alConfirmar,
      void Function(ResultadoDeConfirmacion) alTerminar, {
      bool oscuro = false,
    }) {
      return montar(
        tester,
        Builder(
          builder: (contexto) => TextButton(
            onPressed: () async => alTerminar(
              await confirmarAccion(
                contexto,
                titulo: 'Confirmar compra',
                detalle: 'Compra a mercado',
                simbolo: 'QLD',
                monto: 250,
                textoConfirmar: 'Comprar',
                alConfirmar: alConfirmar,
              ),
            ),
            child: const Text('Abrir'),
          ),
        ),
        oscuro: oscuro,
      );
    }

    testWidgets('repite el símbolo y el monto antes de confirmar', (
      tester,
    ) async {
      await montarConBoton(tester, () async {}, (_) {});
      await abrirDialogo(tester);

      expect(find.text('Confirmar compra'), findsOneWidget);
      expect(find.text('Compra a mercado'), findsOneWidget);
      expect(find.text('QLD'), findsOneWidget);
      expect(find.text(formatearUsd(250)), findsOneWidget);
      expect(find.text('Comprar'), findsOneWidget);
      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('mientras envía dice Procesando… y no deja cancelar', (
      tester,
    ) async {
      final respuesta = Completer<void>();
      ResultadoDeConfirmacion? resultado;
      await montarConBoton(
        tester,
        () => respuesta.future,
        (r) => resultado = r,
      );
      await abrirDialogo(tester);

      await tester.tap(find.text('Comprar'));
      await tester.pump();

      expect(find.text(textoProcesando), findsOneWidget);
      expect(find.text('Comprar'), findsNothing);
      final cancelar = tester.widget<TextButton>(
        find.widgetWithText(TextButton, 'Cancelar'),
      );
      expect(cancelar.onPressed, isNull);
      expect(resultado, isNull);

      respuesta.complete();
      await tester.pumpAndSettle();
      expect(find.text('Confirmar compra'), findsNothing);
      expect(resultado, ResultadoDeConfirmacion.hecho);
    });

    testWidgets('cancelar cierra sin ejecutar la acción', (tester) async {
      var ejecutada = false;
      ResultadoDeConfirmacion? resultado;
      await montarConBoton(tester, () async {
        ejecutada = true;
      }, (r) => resultado = r);
      await abrirDialogo(tester);

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar compra'), findsNothing);
      expect(resultado, ResultadoDeConfirmacion.cancelado);
      expect(ejecutada, isFalse);
    });

    testWidgets('un error se muestra ya traducido y deja reintentar', (
      tester,
    ) async {
      var intento = 0;
      ResultadoDeConfirmacion? resultado;
      await montarConBoton(tester, () async {
        if (++intento == 1) throw const ErrorDeNegocio('MERCADO_CERRADO');
      }, (r) => resultado = r);
      await abrirDialogo(tester);

      await tester.tap(find.text('Comprar'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar compra'), findsOneWidget);
      expect(find.text('El mercado está cerrado.'), findsOneWidget);
      expect(find.text('Comprar'), findsOneWidget);
      expect(resultado, isNull);

      await tester.tap(find.text('Comprar'));
      await tester.pumpAndSettle();

      expect(find.text('Confirmar compra'), findsNothing);
      expect(resultado, ResultadoDeConfirmacion.hecho);
    });

    testWidgets('un error desconocido no muestra su texto crudo', (
      tester,
    ) async {
      await montarConBoton(
        tester,
        () async => throw StateError('detalle técnico'),
        (_) {},
      );
      await abrirDialogo(tester);

      await tester.tap(find.text('Comprar'));
      await tester.pumpAndSettle();

      expect(find.textContaining('detalle técnico'), findsNothing);
      expect(find.text(mensajeGenerico), findsOneWidget);
    });

    testWidgets('se ve en oscuro y con el texto al doble sin desbordar', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      tester.platformDispatcher.textScaleFactorTestValue = 2;
      addTearDown(tester.platformDispatcher.clearTextScaleFactorTestValue);

      await montarConBoton(tester, () async {}, (_) {}, oscuro: true);
      await abrirDialogo(tester);

      expect(find.text('Confirmar compra'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
