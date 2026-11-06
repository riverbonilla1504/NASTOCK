import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/configuracion/entorno.dart';
import 'package:inversiones/core/supabase/cliente_supabase.dart';

void main() {
  group('Entorno', () {
    test('está configurado solo con URL y llave publicable', () {
      const completo = Entorno(
        supabaseUrl: 'http://127.0.0.1:54321',
        supabaseLlavePublicable: 'llave-publicable-de-prueba',
      );
      const sinUrl = Entorno(
        supabaseUrl: '',
        supabaseLlavePublicable: 'llave-publicable-de-prueba',
      );
      const sinLlave = Entorno(
        supabaseUrl: 'http://127.0.0.1:54321',
        supabaseLlavePublicable: '',
      );

      expect(completo.supabaseConfigurado, isTrue);
      expect(sinUrl.supabaseConfigurado, isFalse);
      expect(sinLlave.supabaseConfigurado, isFalse);
    });

    test('el modo de pruebas viene apagado', () {
      const entorno = Entorno(supabaseUrl: '', supabaseLlavePublicable: '');
      expect(entorno.modoPruebas, isFalse);
    });

    test('sin --dart-define no hay configuración', () {
      expect(Entorno.actual.supabaseConfigurado, isFalse);
      expect(Entorno.actual.modoPruebas, isFalse);
    });
  });

  group('iniciarSupabase', () {
    test('sin configuración no inicia nada y lo avisa con false', () async {
      const sinConfigurar = Entorno(
        supabaseUrl: '',
        supabaseLlavePublicable: '',
      );
      expect(await iniciarSupabase(sinConfigurar), isFalse);
    });
  });
}
