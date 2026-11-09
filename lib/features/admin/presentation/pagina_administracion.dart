/// Pantalla de Administración (`/admin`, docs/03 §3): la lista de secciones del
/// Administrador y, mientras el fondo no tiene capital, la guía de primeros
/// pasos (CB-80). Solo trae las entradas del MVP corto (docs/14 §4.1): Usuarios
/// e invitaciones, Capital, Cupos y Parámetros e interruptores. Una entrada
/// está deshabilitada hasta que su historia registra la subruta en
/// `destinos.dart`.
///
/// Es experiencia de uso, no seguridad: a esta ruta solo llega el Administrador
/// por la guarda de `/admin/*` (HU-006) y cada acción la decide la base de
/// datos.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/destinos.dart';
import '../../../app/rutas.dart';
import '../../../app/tema.dart';
import '../../../shared/widgets/barra_superior.dart';
import '../../../shared/widgets/chip_de_estado.dart';
import '../../../shared/widgets/forma_de_linea.dart';
import '../../../shared/widgets/tarjeta.dart';
import '../data/fondo_repositorio.dart';
import 'guia_de_primeros_pasos.dart';

/// Ancho máximo del contenido en ventanas anchas.
const double anchoMaximoDeAdministracion = 720;

/// Clave de la entrada a Invitaciones, para las pruebas.
const Key claveDeEntradaAInvitaciones = Key('entrada-invitaciones');

/// Clave de la entrada a Cupos (HU-100), para las pruebas.
const Key claveDeEntradaACupos = Key('entrada-cupos');

/// Clave de la guía de primeros pasos, para las pruebas.
const Key claveDeGuiaDePrimerosPasos = Key('guia-de-primeros-pasos');

/// Clave de la entrada de una sección, para las pruebas.
Key claveDeEntrada(String seccion) => Key('entrada-$seccion');

/// Una entrada de la lista.
typedef _Seccion = ({
  String clave,
  IconData icono,
  String titulo,
  String descripcion,
  String ruta,
});

const List<_Seccion> _secciones = [
  (
    clave: 'invitaciones',
    icono: Icons.person_add_alt,
    titulo: 'Usuarios e invitaciones',
    descripcion:
        'Invita a una persona con su Gmail o revoca una invitación '
        'pendiente.',
    ruta: Rutas.adminUsuarios,
  ),
  (
    clave: 'capital',
    icono: Icons.savings_outlined,
    titulo: 'Capital',
    descripcion: 'Registra y anula aportes y mira cuándo se confirman.',
    ruta: Rutas.adminCapital,
  ),
  (
    clave: 'cupos',
    icono: Icons.account_balance_wallet_outlined,
    titulo: 'Cupos',
    descripcion: 'Asigna o reduce el dinero de cada persona.',
    ruta: Rutas.adminCupos,
  ),
  (
    clave: 'parametros',
    icono: Icons.tune,
    titulo: 'Parámetros e interruptores',
    descripcion: 'Ajusta las reglas del fondo y enciende la IA y el trading.',
    ruta: Rutas.adminParametros,
  ),
];

class PaginaAdministracion extends ConsumerWidget {
  const PaginaAdministracion({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mientras carga o si falla la lectura no se muestra la guía: solo se
    // muestra cuando se sabe que el fondo aún no tiene capital.
    final sinCapital = ref.watch(fondoConCapitalProvider).value == false;
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
              if (sinCapital) ...[
                const GuiaDePrimerosPasos(key: claveDeGuiaDePrimerosPasos),
                const SizedBox(height: Espacio.x4),
              ],
              for (final seccion in _secciones)
                Padding(
                  padding: const EdgeInsets.only(bottom: Espacio.x3),
                  child: _EntradaDeSeccion(
                    key: seccion.clave == 'invitaciones'
                        ? claveDeEntradaAInvitaciones
                        : claveDeEntrada(seccion.clave),
                    icono: seccion.icono,
                    titulo: seccion.titulo,
                    descripcion: seccion.descripcion,
                    alTocar: seccionDeAdministracionDisponible(seccion.ruta)
                        ? () => context.push(seccion.ruta)
                        : null,
                  ),
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

  /// `null`: la pantalla de la sección aún no existe.
  final VoidCallback? alTocar;

  @override
  Widget build(BuildContext context) {
    final c = context.colores;
    final textos = Theme.of(context).textTheme;
    return MergeSemantics(
      child: Semantics(
        button: alTocar != null,
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
              if (alTocar == null)
                const ChipDeEstado(
                  etiqueta: 'Próximamente',
                  forma: FormaDeLinea.discontinua,
                )
              else
                Icon(Icons.chevron_right, color: c.tinta),
            ],
          ),
        ),
      ),
    );
  }
}
