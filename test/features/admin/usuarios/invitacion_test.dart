import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/perfil/perfil.dart';
import 'package:inversiones/features/admin/usuarios/domain/invitacion.dart';

import 'ayudas.dart';

void main() {
  group('Invitacion.desdeJson', () {
    test('lee la fila que devuelven la tabla y las RPC', () {
      final i = Invitacion.desdeJson({
        'id': '00000000-0000-4000-8000-0000000000a1',
        'email': 'ana@gmail.com',
        'rol': 'analista',
        'cupo_inicial': 250.5,
        'estado': 'aceptada',
        'expira_en': '2026-11-15T10:30:00+00:00',
        'creado_en': '2026-11-08T10:30:00+00:00',
        'aceptada_en': '2026-11-09T12:00:00+00:00',
        'revocada_en': null,
      });

      expect(i.email, 'ana@gmail.com');
      expect(i.rol, RolApp.analista);
      expect(i.cupoInicial, 250.5);
      expect(i.estado, EstadoInvitacion.aceptada);
      expect(i.expiraEn, DateTime.utc(2026, 11, 15, 10, 30));
      expect(i.aceptadaEn, DateTime.utc(2026, 11, 9, 12));
      expect(i.revocadaEn, isNull);
    });

    test('acepta un cupo entero', () {
      final i = Invitacion.desdeJson({
        'id': 'x',
        'email': 'ana@gmail.com',
        'rol': 'usuario',
        'cupo_inicial': 100,
        'estado': 'pendiente',
        'expira_en': '2026-11-15T10:30:00+00:00',
        'creado_en': '2026-11-08T10:30:00+00:00',
      });
      expect(i.cupoInicial, 100.0);
    });

    test('falla con un rol o un estado desconocidos', () {
      Map<String, dynamic> fila({
        String rol = 'usuario',
        String estado = 'pendiente',
      }) => {
        'id': 'x',
        'email': 'ana@gmail.com',
        'rol': rol,
        'cupo_inicial': 0,
        'estado': estado,
        'expira_en': '2026-11-15T10:30:00+00:00',
        'creado_en': '2026-11-08T10:30:00+00:00',
      };
      expect(
        () => Invitacion.desdeJson(fila(rol: 'superadmin')),
        throwsFormatException,
      );
      expect(
        () => Invitacion.desdeJson(fila(estado: 'otra')),
        throwsFormatException,
      );
    });
  });

  group('estado visible', () {
    test('una pendiente con la fecha por delante es pendiente y vigente', () {
      final i = invitacion();
      expect(i.estadoVisible(ahoraDePrueba), EstadoInvitacion.pendiente);
      expect(i.estaVigente(ahoraDePrueba), isTrue);
    });

    test('una pendiente con la fecha pasada se ve vencida y no vigente', () {
      final i = invitacion(
        expiraEn: ahoraDePrueba.subtract(const Duration(minutes: 1)),
      );
      expect(i.estado, EstadoInvitacion.pendiente);
      expect(i.estadoVisible(ahoraDePrueba), EstadoInvitacion.vencida);
      expect(i.estaVigente(ahoraDePrueba), isFalse);
    });

    test('justo en la fecha de vencimiento ya está vencida', () {
      final i = invitacion(expiraEn: ahoraDePrueba);
      expect(i.estadoVisible(ahoraDePrueba), EstadoInvitacion.vencida);
    });

    test('las demás conservan su estado, aunque su fecha haya pasado', () {
      for (final estado in [
        EstadoInvitacion.aceptada,
        EstadoInvitacion.revocada,
        EstadoInvitacion.vencida,
      ]) {
        final i = invitacion(
          estado: estado,
          expiraEn: ahoraDePrueba.subtract(const Duration(days: 1)),
        );
        expect(i.estadoVisible(ahoraDePrueba), estado);
        expect(i.estaVigente(ahoraDePrueba), isFalse);
      }
    });
  });
}
