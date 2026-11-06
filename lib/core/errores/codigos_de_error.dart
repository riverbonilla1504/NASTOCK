/// Catálogo de códigos de error y su mensaje en español (docs/06 §9).
///
/// Las funciones de la base de datos fallan con `raise exception '<CODIGO>'`
/// (y detalle en `DETAIL`). La app traduce el código con este catálogo y
/// nunca muestra el texto crudo de Postgres.
library;

/// Mensaje para cualquier código que no está en el catálogo.
const String mensajeGenerico =
    'Ocurrió un error inesperado. Inténtalo de nuevo.';

/// Mensaje de cada código del catálogo de 06 §9, salvo `REGLA_RR_xx`
/// (ver [reglasDeRiesgo]).
///
/// Dos mensajes de 06 §9 llevan un dato variable: `MERCADO_CERRADO` ("Abre a
/// las HH:MM.") y `PARAMETRO_FUERA_DE_RANGO` ("(mín.–máx.)"). Aquí van sin
/// ese dato; `traducirCodigo` lo agrega cuando el error lo trae.
const Map<String, String> mensajesPorCodigo = {
  'SESION_INVALIDA': 'Tu sesión no es válida. Vuelve a ingresar.',
  'NO_AUTORIZADO': 'No tienes permiso para esta acción.',
  'NO_EXISTE': 'Lo que buscas ya no existe.',
  'ESTADO_INVALIDO':
      'Esta operación ya cambió de estado. Actualiza la pantalla.',
  'YA_DECIDIDA': 'Ya registraste una decisión distinta sobre esta sugerencia.',
  'VENCIDA': 'La sugerencia venció.',
  'FUERA_DE_BANDA':
      'El precio se movió más de lo permitido desde la sugerencia.',
  'MERCADO_CERRADO': 'El mercado está cerrado.',
  'FUERA_DE_VENTANA':
      'No se abren compras tan cerca de la apertura o del cierre.',
  'FONDOS_INSUFICIENTES': 'No tienes disponible suficiente.',
  'DATO_DESACTUALIZADO':
      'El precio no está actualizado. Intenta en unos segundos.',
  'TRADING_PAUSADO': 'La operación está pausada por el administrador.',
  'IA_PAUSADA': 'El agente de IA está pausado.',
  'INTEGRACION_CAIDA': 'El broker o los datos de mercado no están disponibles.',
  'MISMO_ANALISTA': 'La segunda aprobación debe hacerla otro analista.',
  'ULTIMO_ADMIN': 'Debe quedar al menos un administrador activo.',
  'AUTO_ACCION': 'No puedes aplicarte esta acción a ti mismo.',
  'CUPO_CON_POSICIONES': 'El cupo tiene posiciones u órdenes abiertas.',
  'PARAMETRO_FUERA_DE_RANGO': 'El valor está fuera del rango permitido.',
  'INVITACION_DUPLICADA': 'Ya existe una invitación vigente para ese correo.',
  'CORREO_YA_REGISTRADO': 'Ese correo ya tiene una cuenta.',
  'CUPO_SUPERA_MAXIMO': 'El cupo supera el máximo permitido por persona.',
  'FONDO_SIN_CAPITAL': 'Fondo sin capital.',
};

/// Texto de cada regla de riesgo (docs/02 §9), para `REGLA_RR_xx`: 06 §9 dice
/// "Texto de la regla violada (02 §9)". Es el texto de la columna "Regla" de la
/// tabla de 02 §9, sin enlaces ni comillas de código.
const Map<String, String> reglasDeRiesgo = {
  'RR-01': 'El símbolo está en la lista blanca activa del bolsillo.',
  'RR-02': 'Ninguna orden usa la Reserva ni usuarios_comun.',
  'RR-03': 'El monto no supera el disponible de la subcuenta.',
  'RR-04': 'Monto por operación ≤ % del patrimonio de la subcuenta.',
  'RR-05':
      'Concentración: valor en un símbolo tras la compra ≤ % del patrimonio.',
  'RR-06': 'Monto mínimo de orden.',
  'RR-07':
      'Mercado en horario regular; compras solo entre apertura + 5 min y '
      'cierre − 15 min.',
  'RR-08': 'Stop-loss obligatorio en toda compra, dentro de un rango.',
  'RR-09':
      'Confianza de JEV en la decisión ≥ mínima (y el resto de reglas de '
      'decisión de 07 §6.3).',
  'RR-10':
      'Sin duplicados: no puede haber otra sugerencia u orden viva para la '
      'misma subcuenta, símbolo y lado.',
  'RR-11': 'Cotización fresca: el último precio tiene menos de N segundos.',
  'RR-12':
      'Banda de precio: el precio actual no se alejó más de X % del de '
      'referencia.',
  'RR-13':
      'Doble aprobación si el monto ≥ umbral. Si hay menos de 2 analistas '
      'activos, la IA recorta el monto al umbral.',
  'RR-14':
      'Interruptores: ia_activa para crear sugerencias; trading_activo para '
      'enviar órdenes nuevas (las protecciones y liquidaciones siguen).',
  'RR-15': 'Solo se vende lo que se tiene (sin cortos).',
  'RR-16': 'Máximo de sugerencias por cupo por día.',
  'RR-17': 'El destinatario está activo (no suspendido ni de baja).',
  'RR-18': 'Sin margen, sin cortos, sin opciones, sin horario extendido.',
  'RR-19':
      'Pérdida diaria máxima: si Arriesgadas pierde más de X % de su '
      'patrimonio en el día, no se aceptan compras nuevas hasta el día '
      'siguiente.',
  'RR-20':
      'Enfriamiento: tras una venta por stop-loss en un símbolo, no se '
      'recompra ese símbolo en esa subcuenta durante N horas.',
  'RR-21':
      'Salud: broker y datos de mercado en estado ok o degradado. Con caido '
      'no se crean ni ejecutan operaciones.',
  'RR-22': 'Conciliación sin descuadre crítico abierto.',
};
