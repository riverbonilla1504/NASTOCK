import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/errores/fallo_de_ingreso.dart';
import 'package:inversiones/core/errores/traduccion_de_errores.dart';

void main() {
  group('Textos propios de cada fallo (docs/04 §11)', () {
    test('cada tipo tiene su mensaje', () {
      expect(
        mensajesDeIngreso.keys.toSet(),
        TipoDeFalloDeIngreso.values.toSet(),
      );
    });

    test('ningún texto habla de cuenta corporativa ni de RiTech', () {
      for (final texto in mensajesDeIngreso.values) {
        expect(texto.toLowerCase(), isNot(contains('corporativ')));
        expect(texto, isNot(contains('RiTech')));
      }
    });

    test('los que no cambian con la decisión del 2026-11-08 son los de docs/04 §11', () {
      final doc = File('docs/04-autenticacion-oauth.md').readAsStringSync();
      const iguales = [
        TipoDeFalloDeIngreso.sinInvitacion,
        TipoDeFalloDeIngreso.cuentaSuspendida,
        TipoDeFalloDeIngreso.sinConexion,
        TipoDeFalloDeIngreso.inesperado,
      ];
      for (final tipo in iguales) {
        expect(doc, contains('"${mensajesDeIngreso[tipo]}"'), reason: '$tipo');
      }
    });

    test('los dos rechazos del hook con redacción nueva', () {
      expect(
        mensajesDeIngreso[TipoDeFalloDeIngreso.dominioNoPermitido],
        'Solo se admiten cuentas de Google invitadas.',
      );
      expect(
        mensajesDeIngreso[TipoDeFalloDeIngreso.proveedorNoPermitido],
        'Solo puedes ingresar con tu cuenta de Google.',
      );
    });
  });

  group('FalloDeIngreso.mensaje', () {
    test('sin texto del servidor muestra el propio', () {
      for (final tipo in TipoDeFalloDeIngreso.values) {
        expect(FalloDeIngreso(tipo).mensaje, mensajesDeIngreso[tipo]);
      }
    });

    test('en un rechazo del hook muestra el texto que llegó del servidor', () {
      const fallo = FalloDeIngreso(
        TipoDeFalloDeIngreso.dominioNoPermitido,
        textoDelServidor: '  Solo se admiten cuentas con otra redacción.  ',
      );

      expect(fallo.esRechazoDelHook, isTrue);
      expect(fallo.mensaje, 'Solo se admiten cuentas con otra redacción.');
    });

    test('un texto del servidor vacío usa el propio', () {
      const fallo = FalloDeIngreso(
        TipoDeFalloDeIngreso.sinInvitacion,
        textoDelServidor: '   ',
      );

      expect(
        fallo.mensaje,
        mensajesDeIngreso[TipoDeFalloDeIngreso.sinInvitacion],
      );
    });

    test(
      'fuera de los rechazos del hook el texto del servidor nunca se muestra',
      () {
        for (final tipo in [
          TipoDeFalloDeIngreso.cuentaSuspendida,
          TipoDeFalloDeIngreso.sinConexion,
          TipoDeFalloDeIngreso.inesperado,
        ]) {
          final fallo = FalloDeIngreso(
            tipo,
            textoDelServidor: 'detalle técnico',
          );

          expect(fallo.esRechazoDelHook, isFalse);
          expect(fallo.mensaje, mensajesDeIngreso[tipo]);
          expect(fallo.mensaje, isNot(contains('detalle técnico')));
        }
      },
    );
  });

  group('traducirError', () {
    test('reconoce un FalloDeIngreso', () {
      expect(
        traducirError(const FalloDeIngreso(TipoDeFalloDeIngreso.sinConexion)),
        'No hay conexión. Revisa tu internet e inténtalo de nuevo.',
      );
    });
  });
}
