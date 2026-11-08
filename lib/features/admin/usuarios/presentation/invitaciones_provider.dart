/// Estado de la lista de invitaciones del Administrador (docs/05 §9.2).
///
/// Foto por la API y, después de cada acción, se vuelve a pedir la lista. Escuchar el
/// canal `admin` para que la lista se actualice sola con el evento `invitacion` llega con
/// HU-084 y HU-098 (el servidor ya lo publica, HU-003).
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/perfil/perfil.dart';
import '../data/invitaciones_repositorio.dart';
import '../domain/invitacion.dart';

/// La hora con la que se decide si una invitación ya venció al mostrarla. Solo
/// informa: quien decide si una invitación sirve es la base de datos.
final ahoraProvider = Provider<DateTime Function()>((ref) => DateTime.now);

final invitacionesProvider =
    AsyncNotifierProvider<InvitacionesNotifier, List<Invitacion>>(
      InvitacionesNotifier.new,
    );

class InvitacionesNotifier extends AsyncNotifier<List<Invitacion>> {
  @override
  Future<List<Invitacion>> build() =>
      ref.watch(invitacionesRepositorioProvider).listar();

  /// Vuelve a pedir la lista sin quitar la que ya se ve: al asignar un estado de
  /// carga o de error, Riverpod conserva los datos anteriores. Si falla, el error
  /// queda en el estado (junto a la lista anterior) y la pantalla lo muestra; no
  /// se lanza.
  Future<void> recargar() async {
    state = const AsyncLoading<List<Invitacion>>();
    try {
      state = AsyncData(
        await ref.read(invitacionesRepositorioProvider).listar(),
      );
    } catch (error, pila) {
      state = AsyncError<List<Invitacion>>(error, pila);
    }
  }

  /// Invita y vuelve a pedir la lista. Si la RPC falla, lanza su excepción
  /// (la pantalla la traduce con `traducirError`).
  Future<Invitacion> invitar({
    required String email,
    required RolApp rol,
    required double cupoInicial,
  }) async {
    final invitacion = await ref
        .read(invitacionesRepositorioProvider)
        .invitar(email: email, rol: rol, cupoInicial: cupoInicial);
    await recargar();
    return invitacion;
  }

  /// Revoca una invitación y vuelve a pedir la lista. Si la RPC falla, lanza
  /// su excepción; la lista se vuelve a pedir igual, porque un error como
  /// `ESTADO_INVALIDO` significa que la pantalla estaba desactualizada.
  Future<Invitacion> revocar(String id) async {
    try {
      return await ref.read(invitacionesRepositorioProvider).revocar(id);
    } finally {
      await recargar();
    }
  }
}
