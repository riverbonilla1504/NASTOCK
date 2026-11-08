/// Pantalla de invitaciones del Administrador (HU-003, PM-50): el formulario
/// para invitar y la lista con su estado. HU-098 la amplía con las cuentas en
/// la pantalla "Usuarios e invitaciones" y reutiliza estos dos widgets.
///
/// La seguridad no está aquí: invitar y revocar los decide la base de datos por
/// el perfil activo (RPC `invitar_usuario` y `revocar_invitacion`, RLS de
/// `invitaciones`). La app solo no ofrece la pantalla a quien no es
/// Administrador: la ruta `/admin/usuarios` cuelga del destino Administración,
/// que la guarda de `/admin/*` (HU-006) abre solo a ese rol.
library;

import 'package:flutter/material.dart';

import '../../../../app/tema.dart';
import '../../../../shared/widgets/barra_superior.dart';
import '../../../../shared/widgets/tarjeta.dart';
import 'formulario_de_invitacion.dart';
import 'lista_de_invitaciones.dart';

/// Ancho máximo del contenido en ventanas anchas.
const double anchoMaximoDeInvitaciones = 720;

class PaginaInvitaciones extends StatelessWidget {
  const PaginaInvitaciones({super.key});

  @override
  Widget build(BuildContext context) {
    // Deja libre el espacio de la isla de navegación, que flota sobre el cuerpo.
    final abajo = MediaQuery.paddingOf(context).bottom + Espacio.x4;
    return Scaffold(
      appBar: const BarraSuperior(titulo: 'Invitaciones'),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: anchoMaximoDeInvitaciones,
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              Espacio.x4,
              Espacio.x4,
              Espacio.x4,
              abajo + Espacio.x4,
            ),
            children: const [
              Tarjeta(child: FormularioDeInvitacion()),
              SizedBox(height: Espacio.x6),
              ListaDeInvitaciones(),
            ],
          ),
        ),
      ),
    );
  }
}
