import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/catalogo/pagina_catalogo.dart';
import 'package:inversiones/app/enrutador.dart';

void main() {
  group('redirigirSegunSesion (05 §9.3: sin sesión → /ingreso)', () {
    test('sin sesión, cualquier ruta lleva al ingreso', () {
      for (final ruta in [
        '/inicio',
        '/',
        '/admin/usuarios',
        '/riesgo/bandeja',
      ]) {
        expect(
          redirigirSegunSesion(ruta: ruta, haySesion: false),
          Rutas.ingreso,
          reason: ruta,
        );
      }
    });

    test('sin sesión, el ingreso se queda donde está', () {
      expect(
        redirigirSegunSesion(ruta: Rutas.ingreso, haySesion: false),
        isNull,
      );
    });

    test('con sesión, el ingreso lleva al inicio', () {
      expect(
        redirigirSegunSesion(ruta: Rutas.ingreso, haySesion: true),
        Rutas.inicio,
      );
    });

    test('con sesión, el resto de las rutas se queda donde está', () {
      for (final ruta in ['/inicio', '/admin/usuarios']) {
        expect(redirigirSegunSesion(ruta: ruta, haySesion: true), isNull);
      }
    });

    test('el catálogo de componentes no pide sesión', () {
      for (final ruta in [
        RutasCatalogo.inicio,
        RutasCatalogo.mercado,
        RutasCatalogo.componentes,
      ]) {
        expect(redirigirSegunSesion(ruta: ruta, haySesion: false), isNull);
      }
    });

    test('una ruta que solo empieza parecido al catálogo sí pide sesión', () {
      expect(
        redirigirSegunSesion(ruta: '/catalogos', haySesion: false),
        Rutas.ingreso,
      );
    });
  });
}
