/// Estado de Oportunidades (HU-048): la foto del último ciclo por la RPC.
///
/// El patrón foto y eventos de HU-084 (gestor de tiempo real) todavía no está en
/// `main`: mientras tanto la pantalla se actualiza al deslizar hacia abajo y sola
/// cada minuto (el agente corre cada 15 minutos con el mercado abierto). El
/// servidor ya publica el evento `ciclo_agente` en el canal `supervision`.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/oportunidades_repositorio.dart';
import '../domain/oportunidad.dart';

/// Cada cuánto se vuelve a pedir la foto si la pantalla sigue abierta.
const Duration intervaloDeRefresco = Duration(minutes: 1);

/// Todas las evaluaciones que el rol puede ver, ya filtradas por la base de
/// datos. La pantalla las separa por bolsillo.
final oportunidadesProvider = FutureProvider<List<Oportunidad>>(
  (ref) => ref.watch(oportunidadesRepositorioProvider).listar(),
);
