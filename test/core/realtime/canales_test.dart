import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/perfil/perfil.dart';
import 'package:inversiones/core/realtime/canales.dart';

void main() {
  group('CA-1: canales que abre cada rol (docs/09 §3)', () {
    test('el Usuario abre mercado, fondo y su canal', () {
      expect(canalesDeRol(RolApp.usuario, 'u-1'), [
        'mercado',
        'fondo',
        'usuario:u-1',
      ]);
    });

    test('el Analista, además, supervision', () {
      expect(canalesDeRol(RolApp.analista, 'u-2'), [
        'mercado',
        'fondo',
        'usuario:u-2',
        'supervision',
      ]);
    });

    test('el Administrador, además, supervision y admin', () {
      expect(canalesDeRol(RolApp.administrador, 'u-3'), [
        'mercado',
        'fondo',
        'usuario:u-3',
        'supervision',
        'admin',
      ]);
    });
  });
}
