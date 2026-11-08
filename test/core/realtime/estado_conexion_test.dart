import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/realtime/estado_conexion.dart';

void main() {
  const canales = ['mercado', 'fondo'];

  ControlDeConexion conectado() {
    final control = ControlDeConexion(canales);
    for (final c in canales) {
      control.alSenal(CanalSuscrito(c));
    }
    return control;
  }

  group('CA-3 / CB-66: pérdida y recuperación de la conexión', () {
    test('arranca conectado y la suscripción inicial no es una reconexión', () {
      final control = ControlDeConexion(canales);
      expect(control.estado, EstadoConexion.conectado);
      expect(control.alSenal(const CanalSuscrito('mercado')), isFalse);
      expect(control.alSenal(const CanalSuscrito('fondo')), isFalse);
      expect(control.estado, EstadoConexion.conectado);
    });

    test('al cerrarse el socket pasa a reconectando', () {
      final control = conectado();
      control.alSenal(const SocketCerrado());
      expect(control.estado, EstadoConexion.reconectando);
      expect(control.canalesSuscritos, isEmpty);
    });

    test('al caer un canal pasa a reconectando', () {
      final control = conectado();
      control.alSenal(const CanalCaido('fondo'));
      expect(control.estado, EstadoConexion.reconectando);
    });

    test('un error con la conexión abierta pasa a reconectando', () {
      final control = conectado();
      control.alSenal(const SocketFallo());
      expect(control.estado, EstadoConexion.reconectando);
    });

    test('si el intento de reconectar también falla, queda sin conexión', () {
      final control = conectado();
      control.alSenal(const SocketCerrado());
      control.alSenal(const SocketFallo());
      expect(control.estado, EstadoConexion.sinConexion);
    });

    test('al volver a suscribir todos los canales avisa la reconexión', () {
      final control = conectado();
      control.alSenal(const SocketCerrado());
      expect(control.alSenal(const SocketAbierto()), isFalse);
      expect(control.alSenal(const CanalSuscrito('mercado')), isFalse);
      expect(control.estado, EstadoConexion.reconectando);

      expect(control.alSenal(const CanalSuscrito('fondo')), isTrue);
      expect(control.estado, EstadoConexion.conectado);
    });

    test('desde sin conexión también avisa la reconexión', () {
      final control = conectado();
      control.alSenal(const SocketCerrado());
      control.alSenal(const SocketFallo());
      control.alSenal(const SocketAbierto());
      expect(control.estado, EstadoConexion.reconectando);
      control.alSenal(const CanalSuscrito('mercado'));
      expect(control.alSenal(const CanalSuscrito('fondo')), isTrue);
      expect(control.estado, EstadoConexion.conectado);
    });

    test('una suscripción repetida estando conectado no avisa nada', () {
      final control = conectado();
      expect(control.alSenal(const CanalSuscrito('mercado')), isFalse);
      expect(control.estado, EstadoConexion.conectado);
    });

    test('ignora canales que no esperaba', () {
      final control = conectado();
      control.alSenal(const SocketCerrado());
      expect(control.alSenal(const CanalSuscrito('admin')), isFalse);
      expect(control.estado, EstadoConexion.reconectando);
    });

    test('si falla la primera conexión, no se queda diciendo conectado', () {
      final control = ControlDeConexion(canales);
      control.alSenal(const SocketFallo());
      expect(control.estado, EstadoConexion.reconectando);
      control.alSenal(const SocketFallo());
      expect(control.estado, EstadoConexion.sinConexion);
    });
  });
}
