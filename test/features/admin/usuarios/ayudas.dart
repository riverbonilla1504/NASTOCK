import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_riverpod/misc.dart' show Override;
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/tema.dart';
import 'package:inversiones/core/perfil/perfil.dart';
import 'package:inversiones/features/admin/usuarios/data/invitaciones_repositorio.dart';
import 'package:inversiones/features/admin/usuarios/domain/invitacion.dart';
import 'package:inversiones/features/admin/usuarios/presentation/invitaciones_provider.dart';
import 'package:inversiones/features/admin/usuarios/presentation/pagina_invitaciones.dart';

/// La hora fija con la que se ven las invitaciones en las pruebas.
final DateTime ahoraDePrueba = DateTime.utc(2026, 11, 8, 15);

/// Una invitación de prueba. Por defecto, pendiente y vigente.
Invitacion invitacion({
  String id = '00000000-0000-4000-8000-0000000000a1',
  String email = 'ana@prueba.test',
  RolApp rol = RolApp.usuario,
  double cupo = 0,
  EstadoInvitacion estado = EstadoInvitacion.pendiente,
  DateTime? expiraEn,
  DateTime? aceptadaEn,
  DateTime? revocadaEn,
}) => Invitacion(
  id: id,
  email: email,
  rol: rol,
  cupoInicial: cupo,
  estado: estado,
  expiraEn: expiraEn ?? ahoraDePrueba.add(const Duration(days: 3)),
  creadoEn: ahoraDePrueba.subtract(const Duration(days: 4)),
  aceptadaEn: aceptadaEn,
  revocadaEn: revocadaEn,
);

/// Repositorio falso: la lista y los errores se cambian a mano, y se anota
/// cada llamada.
class RepositorioFalso implements InvitacionesRepositorio {
  RepositorioFalso({List<Invitacion> invitaciones = const []})
    : invitaciones = [...invitaciones];

  List<Invitacion> invitaciones;
  Object? errorAlListar;
  Object? errorAlInvitar;
  Object? errorAlRevocar;

  /// Si existe, `invitar` y `revocar` esperan a que se complete.
  Completer<void>? espera;

  int listados = 0;
  final List<({String email, RolApp rol, double cupo})> invitados = [];
  final List<String> revocadas = [];

  @override
  Future<List<Invitacion>> listar() async {
    listados++;
    if (errorAlListar != null) throw errorAlListar!;
    return [...invitaciones];
  }

  @override
  Future<Invitacion> invitar({
    required String email,
    required RolApp rol,
    required double cupoInicial,
  }) async {
    await espera?.future;
    if (errorAlInvitar != null) throw errorAlInvitar!;
    invitados.add((email: email, rol: rol, cupo: cupoInicial));
    final creada = invitacion(
      id: '00000000-0000-4000-8000-0000000000b${invitados.length}',
      email: email.toLowerCase(),
      rol: rol,
      cupo: cupoInicial,
      expiraEn: ahoraDePrueba.add(const Duration(days: 7)),
    );
    invitaciones = [creada, ...invitaciones];
    return creada;
  }

  @override
  Future<Invitacion> revocar(String id) async {
    await espera?.future;
    if (errorAlRevocar != null) throw errorAlRevocar!;
    revocadas.add(id);
    final anterior = invitaciones.firstWhere((i) => i.id == id);
    final revocada = invitacion(
      id: anterior.id,
      email: anterior.email,
      rol: anterior.rol,
      cupo: anterior.cupoInicial,
      estado: EstadoInvitacion.revocada,
      revocadaEn: ahoraDePrueba,
    );
    invitaciones = [for (final i in invitaciones) i.id == id ? revocada : i];
    return revocada;
  }
}

/// Los overrides que toda prueba de la pantalla necesita.
List<Override> overridesDe(RepositorioFalso repositorio) => [
  invitacionesRepositorioProvider.overrideWithValue(repositorio),
  ahoraProvider.overrideWithValue(() => ahoraDePrueba),
];

/// Monta [hijo] con el tema del sistema y los overrides de la pantalla, en una
/// ventana de [ancho] por [alto] dp.
Future<void> montarPantalla(
  WidgetTester tester,
  RepositorioFalso repositorio, {
  Widget hijo = const PaginaInvitaciones(),
  double ancho = 900,
  double alto = 1800,
  bool oscuro = false,
  bool asentar = true,
}) async {
  tester.view.physicalSize = Size(ancho, alto);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
  await tester.pumpWidget(
    ProviderScope(
      overrides: overridesDe(repositorio),
      child: MaterialApp(
        theme: oscuro ? crearTemaOscuro() : crearTema(),
        home: hijo,
      ),
    ),
  );
  await (asentar ? tester.pumpAndSettle() : tester.pump());
}
