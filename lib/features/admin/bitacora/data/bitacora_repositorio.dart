import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/supabase/cliente_supabase.dart';

typedef FiltrosDeBitacora = ({
  String actor,
  String accion,
  String entidad,
  DateTime? desde,
  DateTime? hastaExclusiva,
});

typedef RegistroDeBitacora = ({
  int id,
  DateTime momento,
  String? actor,
  String accion,
  String entidad,
  String? entidadId,
});

typedef LeerBitacora = Future<List<RegistroDeBitacora>> Function(
  FiltrosDeBitacora filtros, {
  int? antesDe,
});

const tamanoPaginaDeBitacora = 100;

final leerBitacoraProvider = Provider<LeerBitacora>(
  (ref) => BitacoraRepositorio(ref.watch(clienteSupabaseProvider)).listar,
);

class BitacoraRepositorio {
  const BitacoraRepositorio(this.cliente);

  final SupabaseClient cliente;

  Future<List<RegistroDeBitacora>> listar(
    FiltrosDeBitacora filtros, {
    int? antesDe,
  }) async {
    var consulta = cliente
        .from('auditoria')
        .select('id,momento,actor_id,accion,entidad,entidad_id');
    if (filtros.actor.isNotEmpty) {
      consulta = filtros.actor.toLowerCase() == 'sistema'
          ? consulta.isFilter('actor_id', null)
          : consulta.eq('actor_id', filtros.actor);
    }
    if (filtros.accion.isNotEmpty) {
      consulta = consulta.eq('accion', filtros.accion);
    }
    if (filtros.entidad.isNotEmpty) {
      consulta = consulta.eq('entidad', filtros.entidad);
    }
    if (filtros.desde case final desde?) {
      consulta = consulta.gte('momento', desde.toIso8601String());
    }
    if (filtros.hastaExclusiva case final hasta?) {
      consulta = consulta.lt('momento', hasta.toIso8601String());
    }
    if (antesDe != null) consulta = consulta.lt('id', antesDe);

    final filas = await consulta
        .order('id', ascending: false)
        .limit(tamanoPaginaDeBitacora);
    return [
      for (final fila in filas)
        (
          id: fila['id'] as int,
          momento: DateTime.parse(fila['momento'] as String).toUtc(),
          actor: fila['actor_id'] as String?,
          accion: fila['accion'] as String,
          entidad: fila['entidad'] as String,
          entidadId: fila['entidad_id'] as String?,
        ),
    ];
  }
}
