/// Textos de la pantalla de invitaciones que comparten el formulario y la lista.
library;

import '../../../../core/perfil/perfil.dart';
import '../domain/invitacion.dart';

/// Nombre del rol como lo lee una persona.
String etiquetaDeRol(RolApp rol) => switch (rol) {
  RolApp.usuario => 'Usuario',
  RolApp.analista => 'Analista',
  RolApp.administrador => 'Administrador',
};

/// Nombre del estado de una invitación como lo lee una persona.
String etiquetaDeEstado(EstadoInvitacion estado) => switch (estado) {
  EstadoInvitacion.pendiente => 'Pendiente',
  EstadoInvitacion.aceptada => 'Aceptada',
  EstadoInvitacion.revocada => 'Revocada',
  EstadoInvitacion.vencida => 'Vencida',
};
