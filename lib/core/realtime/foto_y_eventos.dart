/// Patrón "foto + eventos" reutilizable por los repositorios (docs/08 §9.2).
///
/// ```
/// al montar:
///   foto ← consulta por la API (RLS aplica)
///   suscribirse al canal
/// al llegar evento {tabla, id, version}:
///   si version ≤ la que tengo → ignorar (llegó tarde)
///   si no → pedir ese registro por la API y reemplazarlo
/// al reconectar:
///   pedir la foto completa otra vez (pudieron perderse eventos)
/// ```
///
/// Los eventos llevan solo identificadores y versión, nunca montos: el dato
/// siempre se lee por la API, donde aplica RLS (docs/09 §4).
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'evento_de_tiempo_real.dart';
import 'tiempo_real_provider.dart';

/// Una lista de registros que se actualiza sola. Cada pantalla en vivo
/// extiende esta clase y dice cómo se pide su foto, cómo se pide un registro y
/// qué tabla la afecta:
///
/// ```dart
/// class BandejaNotifier extends FotoYEventosNotifier<Sugerencia> {
///   @override String get tabla => 'sugerencias';
///   @override String idDe(Sugerencia s) => s.id;
///   @override int? versionDe(Sugerencia s) => s.version;
///   @override Future<List<Sugerencia>> pedirFoto() => ref.read(repo).todas();
///   @override Future<Sugerencia?> pedirRegistro(String id) => ref.read(repo).una(id);
/// }
/// ```
abstract class FotoYEventosNotifier<T> extends AsyncNotifier<List<T>> {
  /// La tabla cuyos eventos actualizan esta lista (`tabla` de la carga del
  /// evento, docs/09 §4).
  String get tabla;

  /// El identificador de un registro, como texto.
  String idDe(T registro);

  /// La versión de un registro, o `null` si su tabla no tiene versión.
  int? versionDe(T registro);

  /// La foto: todos los registros, pedidos por la API.
  Future<List<T>> pedirFoto();

  /// Un registro por su identificador, o `null` si la API ya no lo entrega
  /// (se borró o dejó de ser visible para esta persona).
  Future<T?> pedirRegistro(String id);

  /// Si [evento] afecta a esta lista. Por defecto, los de entidad de [tabla].
  /// Una pantalla que escucha un canal con eventos de otra forma (por ejemplo
  /// `resumen_cambio`, sin identificador) lo sobrescribe.
  bool aceptaEvento(EventoDeTiempoReal evento) => evento.entidad.tabla == tabla;

  /// Deja la lista en el orden que muestra la pantalla. Por defecto, el del
  /// servidor para la foto y los registros nuevos al final.
  List<T> ordenar(List<T> registros) => registros;

  @override
  Future<List<T>> build() {
    final gestor = ref.watch(gestorDeTiempoRealProvider);
    if (gestor != null) {
      final eventos = gestor.eventos
          .where(aceptaEvento)
          .listen((evento) => unawaited(_alLlegar(evento)));
      // Al reconectar, o al volver a primer plano, pudieron perderse eventos:
      // la foto se pide completa otra vez, sin vaciar la lista que se ve.
      final reconexiones = gestor.reconexiones.listen(
        (_) => ref.invalidateSelf(),
      );
      ref.onDispose(() {
        unawaited(eventos.cancel());
        unawaited(reconexiones.cancel());
      });
    }
    return pedirFoto().then(ordenar);
  }

  Future<void> _alLlegar(EventoDeTiempoReal evento) async {
    final entidad = evento.entidad;
    final id = entidad.id;
    // Un evento sin identificador avisa que algo cambió, no qué: se pide la
    // foto otra vez.
    if (id == null) {
      ref.invalidateSelf();
      return;
    }

    final List<T> actuales;
    try {
      actuales = await future;
    } on Object {
      // La foto falló: la lista no existe todavía. Cuando se vuelva a pedir
      // (al reconectar o al reintentar) ya trae este cambio.
      return;
    }
    if (!ref.mounted) return;

    final tengo = _buscar(actuales, id);
    final versionDelEvento = entidad.version;
    if (tengo != null && versionDelEvento != null) {
      final miVersion = versionDe(tengo);
      if (miVersion != null && versionDelEvento <= miVersion) return;
    }

    final T? nuevo;
    try {
      nuevo = await pedirRegistro(id);
    } on Object {
      // No se pudo leer el registro: la próxima reconexión trae la foto.
      return;
    }
    if (!ref.mounted) return;

    // Mientras se pedía el registro la lista pudo cambiar (otro evento, otra
    // foto): se parte de lo que hay ahora.
    final ahora = state.value ?? actuales;
    final actual = _buscar(ahora, id);
    if (nuevo != null && actual != null) {
      final versionNueva = versionDe(nuevo);
      final versionActual = versionDe(actual);
      // Una respuesta más vieja que la que ya tengo no la reemplaza.
      if (versionNueva != null &&
          versionActual != null &&
          versionNueva < versionActual) {
        return;
      }
    }

    // Reemplaza el registro en su lugar; si ya no existe, lo quita; si es
    // nuevo, lo agrega al final.
    final lista = <T>[];
    for (final registro in ahora) {
      if (idDe(registro) != id) {
        lista.add(registro);
      } else if (nuevo != null) {
        lista.add(nuevo);
      }
    }
    if (actual == null && nuevo != null) lista.add(nuevo);
    state = AsyncData(ordenar(lista));
  }

  T? _buscar(List<T> registros, String id) {
    for (final registro in registros) {
      if (idDe(registro) == id) return registro;
    }
    return null;
  }
}
