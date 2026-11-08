import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/realtime/gestor_de_tiempo_real.dart';
import 'package:inversiones/core/realtime/reloj.dart';
import 'package:inversiones/core/realtime/tiempo_real_provider.dart';

import 'falsos.dart';

void main() {
  group('calcularDesfase', () {
    final base = DateTime.utc(2026, 11, 8, 14, 30);

    test('un teléfono atrasado da un desfase positivo', () {
      // El teléfono marca 14:30:00 y el servidor ya va por 14:35:00.
      final desfase = calcularDesfase(
        envio: base,
        recepcion: base,
        servidor: base.add(const Duration(minutes: 5)),
      );
      expect(desfase, const Duration(minutes: 5));
    });

    test('un teléfono adelantado da un desfase negativo', () {
      final desfase = calcularDesfase(
        envio: base,
        recepcion: base,
        servidor: base.subtract(const Duration(minutes: 3)),
      );
      expect(desfase, const Duration(minutes: -3));
    });

    test('descuenta la mitad del viaje de ida y vuelta', () {
      // La consulta tardó 400 ms: el servidor respondió a los 200 ms. Si dice
      // 14:30:00.200, el reloj del teléfono está bien.
      final desfase = calcularDesfase(
        envio: base,
        recepcion: base.add(const Duration(milliseconds: 400)),
        servidor: base.add(const Duration(milliseconds: 200)),
      );
      expect(desfase, Duration.zero);
    });
  });

  group('CA-5 / CB-70: RelojCorregido', () {
    test('suma el desfase a la hora del dispositivo, en UTC', () {
      final local = DateTime.utc(2026, 11, 8, 14, 0);
      final reloj = RelojCorregido(ahoraLocal: () => local)
          .conDesfase(const Duration(minutes: 7));

      expect(reloj.medido, isTrue);
      expect(reloj.ahora(), DateTime.utc(2026, 11, 8, 14, 7));
    });

    test('la cuenta regresiva usa el desfase y no el reloj del teléfono', () {
      // El teléfono va 7 minutos atrasado: marca las 14:00 cuando son las
      // 14:07. El mercado abre a las 14:30.
      final local = DateTime.utc(2026, 11, 8, 14, 0);
      final apertura = DateTime.utc(2026, 11, 8, 14, 30);
      final sinCorregir = RelojCorregido(ahoraLocal: () => local);
      final corregido = sinCorregir.conDesfase(const Duration(minutes: 7));

      expect(sinCorregir.faltaPara(apertura), const Duration(minutes: 30));
      expect(corregido.faltaPara(apertura), const Duration(minutes: 23));
    });

    test('un momento pasado da una duración negativa', () {
      final reloj = RelojCorregido(
        ahoraLocal: () => DateTime.utc(2026, 11, 8, 15),
      );
      expect(
        reloj.faltaPara(DateTime.utc(2026, 11, 8, 14, 59)),
        const Duration(minutes: -1),
      );
    });
  });

  group('relojProvider', () {
    late DateTime ahoraDelTelefono;
    late RelojRepositorioFalso servidor;
    late FuenteFalsa fuente;
    late GestorDeTiempoReal gestor;
    late ProviderContainer contenedor;

    setUp(() {
      // El teléfono va 7 minutos atrasado y no se mueve en la prueba.
      ahoraDelTelefono = DateTime.utc(2026, 11, 8, 14, 0);
      servidor = RelojRepositorioFalso(
        () => DateTime.utc(2026, 11, 8, 14, 7),
      );
      fuente = FuenteFalsa();
      gestor = GestorDeTiempoReal(fuente, ['mercado']);
      contenedor = ProviderContainer(
        overrides: [
          ahoraLocalProvider.overrideWithValue(() => ahoraDelTelefono),
          relojRepositorioProvider.overrideWithValue(servidor),
          gestorDeTiempoRealProvider.overrideWithValue(gestor),
        ],
      );
      addTearDown(() async {
        contenedor.dispose();
        await gestor.cerrar();
      });
    });

    test('sin sesión no mide: el desfase es cero', () async {
      final sinSesion = ProviderContainer(
        overrides: [
          ahoraLocalProvider.overrideWithValue(() => ahoraDelTelefono),
          relojRepositorioProvider.overrideWithValue(servidor),
          gestorDeTiempoRealProvider.overrideWithValue(null),
        ],
      );
      addTearDown(sinSesion.dispose);

      final reloj = sinSesion.read(relojProvider);
      await Future<void>.delayed(Duration.zero);

      expect(reloj.medido, isFalse);
      expect(sinSesion.read(relojProvider).desfase, Duration.zero);
      expect(servidor.consultas, 0);
    });

    test('con sesión mide el desfase contra el servidor', () async {
      expect(contenedor.read(relojProvider).medido, isFalse);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final reloj = contenedor.read(relojProvider);
      expect(reloj.medido, isTrue);
      expect(reloj.desfase, const Duration(minutes: 7));
      expect(reloj.ahora(), DateTime.utc(2026, 11, 8, 14, 7));
    });

    test('si no puede medir, conserva el desfase que tenía', () async {
      contenedor.read(relojProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      servidor.error = Exception('sin red');

      await contenedor.read(relojProvider.notifier).medir();

      expect(contenedor.read(relojProvider).desfase, const Duration(minutes: 7));
    });

    test('al reconectar vuelve a medir', () async {
      contenedor.read(relojProvider);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(servidor.consultas, 1);

      // Ahora el servidor va 9 minutos adelante.
      servidor.servidor = () => DateTime.utc(2026, 11, 8, 14, 9);
      gestor.alVolverAPrimerPlano();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(servidor.consultas, 2);
      expect(contenedor.read(relojProvider).desfase, const Duration(minutes: 9));
    });
  });
}
