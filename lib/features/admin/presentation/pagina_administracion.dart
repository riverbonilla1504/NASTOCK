/// Pantalla de Administración (`/admin`, docs/03 §3): la lista de secciones del
/// Administrador. Cada historia de la épica E-11 agrega aquí la entrada de su
/// sección; HU-003 trae la primera, Invitaciones.
///
/// Es experiencia de uso, no seguridad: a esta ruta solo llega el Administrador
/// por la guarda de `/admin/*` (HU-006) y cada acción la decide la base de
/// datos.
library;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../app/rutas.dart';
import '../../../app/tema.dart';
import '../../../shared/widgets/barra_superior.dart';
import '../../../shared/widgets/tarjeta.dart';

/// Ancho máximo del contenido en ventanas anchas.
const double anchoMaximoDeAdministracion = 720;

/// Clave de la entrada a Invitaciones, para las pruebas.
const Key claveDeEntradaAInvitaciones = Key('entrada-invitaciones');

/// Clave de la entrada a Cupos (HU-100), para las pruebas.
const Key claveDeEntradaACupos = Key('entrada-cupos');

class PaginaAdministracion extends StatelessWidget {
  const PaginaAdministracion({super.key});

  @override
  Widget build(BuildContext context) {
    // Deja libre el espacio de la isla de navegación, que flota sobre el cuerpo.
    final abajo = MediaQuery.paddingOf(context).bottom + Espacio.x4;
    return Scaffold(
      appBar: const BarraSuperior(titulo: 'Administración'),
      body: Align(
        alignment: Alignment.topCenter,
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: anchoMaximoDeAdministracion,
          ),
          child: ListView(
            padding: EdgeInsets.fromLTRB(
              Espacio.x4,
              Espacio.x4,
              Espacio.x4,
              abajo,
            ),
            children: [
              _EntradaDeSeccion(
                key: claveDeEntradaAInvitaciones,
                icono: Icons.person_add_alt,
                titulo: 'Invitaciones',
                descripcion:
                    'Invita a una persona con su Gmail o revoca una '
                    'invitación pendiente.',
                alTocar: () => context.push(Rutas.adminUsuarios),
              ),
              _EntradaDeSeccion(
                key: claveDeEntradaACupos,
                icono: Icons.account_balance_wallet_outlined,
                titulo: 'Cupos',
                descripcion:
                    'Reparte la bolsa común entre los cupos de los empleados.',
                alTocar: () => context.push(Rutas.adminCupos),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EntradaDeSeccion extends StatelessWidget {
  const _EntradaDeSeccion({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.alTocar,
    super.key,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final VoidCallback alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Semantics(
        button: true,
        child: Tarjeta(
          alTocar: alTocar,
          child: Row(
            children: [
              Icon(icono, color: c.tinta),
              const SizedBox(width: Espacio.x4),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(titulo, style: textos.titleMedium),
                    const SizedBox(height: Espacio.x1),
                    Text(
                      descripcion,
                      style: textos.bodyMedium!.copyWith(color: c.tintaSuave),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: c.tinta),
            ],
          ),
        ),
      ),
    );
  }
}
