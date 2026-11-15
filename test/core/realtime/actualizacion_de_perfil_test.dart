import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/realtime/actualizacion_de_perfil.dart';
import 'package:inversiones/core/realtime/evento_de_tiempo_real.dart';

void main() {
  late StreamController<EventoDeTiempoReal> eventos;
  late ActualizacionDePerfil actualizacion;
  late int renovaciones;
  late List<Object> errores;

  void emitir(String canal, String evento) =>
      eventos.add(EventoDeTiempoReal(canal: canal, evento: evento));

  setUp(() {
    eventos = StreamController.broadcast(sync: true);
    renovaciones = 0;
    errores = [];
    actualizacion = ActualizacionDePerfil(
      eventos: eventos.stream,
      idUsuario: 'propio',
      renovar: () async => renovaciones++,
      alFallar: (error, _) => errores.add(error),
    );
  });

  tearDown(() async {
    await actualizacion.cerrar();
    await eventos.close();
  });

  test('solo renueva por perfil_actualizado en el canal propio', () async {
    emitir('usuario:otro', 'perfil_actualizado');
    emitir('usuario:propio', 'orden');
    expect(renovaciones, 0);
    emitir('usuario:propio', 'perfil_actualizado');
    await Future<void>.delayed(Duration.zero);
    expect(renovaciones, 1);
    expect(errores, isEmpty);
  });

  test('no pierde un cambio recibido durante la renovación', () async {
    await actualizacion.cerrar();
    final primera = Completer<void>();
    actualizacion = ActualizacionDePerfil(
      eventos: eventos.stream,
      idUsuario: 'propio',
      renovar: () async {
        renovaciones++;
        if (renovaciones == 1) await primera.future;
      },
      alFallar: (error, _) => errores.add(error),
    );
    emitir('usuario:propio', 'perfil_actualizado');
    emitir('usuario:propio', 'perfil_actualizado');
    emitir('usuario:propio', 'perfil_actualizado');
    expect(renovaciones, 1);
    primera.complete();
    await Future<void>.delayed(Duration.zero);
    expect(renovaciones, 2);
  });

  test('al cerrar no procesa cambios pendientes ni eventos nuevos', () async {
    await actualizacion.cerrar();
    final primera = Completer<void>();
    actualizacion = ActualizacionDePerfil(
      eventos: eventos.stream,
      idUsuario: 'propio',
      renovar: () async {
        renovaciones++;
        await primera.future;
      },
      alFallar: (error, _) => errores.add(error),
    );
    emitir('usuario:propio', 'perfil_actualizado');
    emitir('usuario:propio', 'perfil_actualizado');
    await actualizacion.cerrar();
    primera.complete();
    emitir('usuario:propio', 'perfil_actualizado');
    await Future<void>.delayed(Duration.zero);
    expect(renovaciones, 1);
  });

  test('informa un fallo y permite renovar con el siguiente evento', () async {
    await actualizacion.cerrar();
    actualizacion = ActualizacionDePerfil(
      eventos: eventos.stream,
      idUsuario: 'propio',
      renovar: () async {
        renovaciones++;
        if (renovaciones == 1) throw StateError('sin conexión');
      },
      alFallar: (error, _) => errores.add(error),
    );
    emitir('usuario:propio', 'perfil_actualizado');
    await Future<void>.delayed(Duration.zero);
    emitir('usuario:propio', 'perfil_actualizado');
    await Future<void>.delayed(Duration.zero);
    expect(renovaciones, 2);
    expect(errores, hasLength(1));
  });
}
