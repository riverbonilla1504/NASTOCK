/// Cómo terminó un intento de ingreso que no falló (docs/04 §4).
library;

enum ResultadoDeIngreso {
  /// La sesión quedó iniciada (ingreso nativo en Android o con correo).
  exito,

  /// La persona cerró la ventana de Google: se vuelve a la pantalla de ingreso
  /// sin mensaje (docs/04 §11).
  cancelado,

  /// Web: la página se va a Google y la sesión llega al volver, por
  /// `onAuthStateChange`.
  redirigido,
}
