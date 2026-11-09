/// Pantalla de Capital del Administrador (`/admin/capital`, HU-099, PM-40):
/// el formulario para registrar un aporte y la lista con su estado. En el MVP
/// corto solo maneja aportes: los retiros (HU-016) y los ajustes (HU-022) salen
/// de él (D-58).
///
/// La seguridad no está aquí: registrar y anular los decide la base de datos
/// por el perfil activo (RPC `registrar_aporte` y `anular_aporte`, RLS de
/// `movimientos_capital`). La ruta cuelga de Administración, que la guarda de
/// `/admin/*` (HU-006) abre solo al Administrador.
library;

import 'package:flutter/material.dart';

import '../../../../app/tema.dart';
import '../../../../shared/widgets/barra_superior.dart';
import '../../../../shared/widgets/tarjeta.dart';
import 'formulario_de_aporte.dart';
import 'lista_de_aportes.dart';

/// Ancho máximo del contenido en ventanas anchas.
const double anchoMaximoDeCapital = 720;

class PaginaCapital extends StatelessWidget {
  const PaginaCapital({super.key});

  @override
  Widget build(BuildContext context) {
    // Deja libre el espacio de la isla de navegación, que flota sobre el cuerpo.
    final abajo = MediaQuery.paddingOf(context).bottom + Espacio.x4;
    return Scaffold(
      appBar: const BarraSuperior(titulo: 'Capital'),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: anchoMaximoDeCapital),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              Espacio.x4,
              Espacio.x4,
              Espacio.x4,
              abajo + Espacio.x4,
            ),
            children: const [
              Tarjeta(child: FormularioDeAporte()),
              SizedBox(height: Espacio.x6),
              ListaDeAportes(),
            ],
          ),
        ),
      ),
    );
  }
}
