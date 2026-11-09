/// El estado de la conexión en vivo y cómo se deduce (docs/08 §9.4, docs/09 §7).
library;

/// `conexionProvider` (docs/08 §9.1).
enum EstadoConexion {
  /// Todos los canales están suscritos.
  conectado,

  /// Se perdió la conexión y la app reintenta sola: barra "Reconectando…" y
  /// datos atenuados.
  reconectando,

  /// Un intento de reconectar falló también: "Sin conexión" y los botones de
  /// decisión quedan deshabilitados.
  sinConexion,
}

/// Lo que observa la fuente de tiempo real y alimenta a [ControlDeConexion].
sealed class SenalDeConexion {
  const SenalDeConexion();
}

/// El socket se abrió.
class SocketAbierto extends SenalDeConexion {
  const SocketAbierto();
}

/// El socket se cerró.
class SocketCerrado extends SenalDeConexion {
  const SocketCerrado();
}

/// Falló la conexión del socket (un intento de abrirlo, o un error en uno
/// abierto).
class SocketFallo extends SenalDeConexion {
  const SocketFallo();
}

/// El servidor aceptó la suscripción a [canal] (también al volver a unirse).
class CanalSuscrito extends SenalDeConexion {
  const CanalSuscrito(this.canal);
  final String canal;
}

/// [canal] dejó de estar suscrito: se cerró, dio error o se agotó el tiempo.
class CanalCaido extends SenalDeConexion {
  const CanalCaido(this.canal);
  final String canal;
}

/// Deduce el [EstadoConexion] de las señales del socket y de los canales.
///
/// - Está `conectado` mientras todos los canales esperados siguen suscritos.
/// - Al perder el socket o un canal pasa a `reconectando`: Realtime reintenta
///   solo (docs/09 §7).
/// - Si un intento de reconectar falla, pasa a `sinConexion`.
/// - Al volver a tener todos los canales suscritos vuelve a `conectado` y
///   [alSenal] avisa que hubo una reconexión: pudieron perderse eventos y hay
///   que pedir las fotos otra vez (CB-66).
///
/// Arranca `conectado`: mientras la primera suscripción no falla no hay nada
/// que avisar. No toca la red; se prueba entregándole señales.
class ControlDeConexion {
  ControlDeConexion(Iterable<String> canales) : _esperados = {...canales};

  final Set<String> _esperados;
  final Set<String> _suscritos = {};
  EstadoConexion _estado = EstadoConexion.conectado;

  EstadoConexion get estado => _estado;

  /// Los canales que ya aceptó el servidor.
  Set<String> get canalesSuscritos => Set.unmodifiable(_suscritos);

  /// Procesa [senal]. Devuelve `true` si con ella la app se reconectó (pasó de
  /// `reconectando` o `sinConexion` a `conectado`).
  bool alSenal(SenalDeConexion senal) {
    switch (senal) {
      case SocketAbierto():
        // Los canales aún tienen que volver a unirse.
        if (_estado == EstadoConexion.sinConexion) {
          _estado = EstadoConexion.reconectando;
        }
        return false;
      case SocketCerrado():
        _suscritos.clear();
        _perderConexion();
        return false;
      case SocketFallo():
        _suscritos.clear();
        _estado = _estado == EstadoConexion.conectado
            ? EstadoConexion.reconectando
            : EstadoConexion.sinConexion;
        return false;
      case CanalCaido(:final canal):
        _suscritos.remove(canal);
        _perderConexion();
        return false;
      case CanalSuscrito(:final canal):
        if (!_esperados.contains(canal)) return false;
        _suscritos.add(canal);
        if (_suscritos.containsAll(_esperados) &&
            _estado != EstadoConexion.conectado) {
          _estado = EstadoConexion.conectado;
          return true;
        }
        return false;
    }
  }

  void _perderConexion() {
    if (_estado == EstadoConexion.conectado) {
      _estado = EstadoConexion.reconectando;
    }
  }
}
