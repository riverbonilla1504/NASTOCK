import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/app/aplicacion.dart';
import 'package:inversiones/app/enrutador.dart';
import 'package:inversiones/core/configuracion/entorno.dart';
import 'package:inversiones/core/realtime/tiempo_real_provider.dart';
import 'package:inversiones/features/auth/data/ingreso_repositorio.dart';
import 'package:inversiones/features/auth/presentation/acceso_de_sesion_provider.dart';
import 'package:inversiones/core/perfil/perfil.dart';

import '../core/realtime/falsos.dart';
import '../features/auth/falsos.dart';

void main() {
  testWidgets(
    'perfil_actualizado renueva acceso, ruta y canales sin ingresar',
    (tester) async {
      final fuente = FuenteFalsa();
      final repo = IngresoRepositorioFalso()
        ..sesionActual = sesionDePrueba(rol: 'administrador', estado: 'activo');
      var renovaciones = 0;
      tester.view.physicalSize = const Size(400, 900);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            ...tiempoRealEnMemoria(
              fuente: fuente,
              renovarPerfil: (id) async {
                expect(id, 'usuario-1');
                renovaciones++;
                repo.sesionActual = sesionDePrueba(
                  rol: 'analista',
                  estado: 'activo',
                );
                repo.sesiones.add(repo.sesionActual);
              },
            ),
            entornoProvider.overrideWithValue(
              const Entorno(
                supabaseUrl: 'http://127.0.0.1:54321',
                supabaseLlavePublicable: 'llave-publicable-de-prueba',
              ),
            ),
            ingresoRepositorioProvider.overrideWithValue(repo),
          ],
          child: const Aplicacion(),
        ),
      );
      await tester.pumpAndSettle();
      final contenedor = ProviderScope.containerOf(
        tester.element(find.byType(Aplicacion)),
      );
      final router = contenedor.read(enrutadorProvider);
      router.go(Rutas.admin);
      await tester.pumpAndSettle();
      expect(router.routeInformationProvider.value.uri.path, Rutas.admin);
      fuente.evento(
        'usuario:usuario-1',
        'perfil_actualizado',
        tabla: 'perfiles',
      );
      await tester.pumpAndSettle();
      expect(renovaciones, 1);
      expect(contenedor.read(accesoDeSesionProvider).rol, RolApp.analista);
      expect(router.routeInformationProvider.value.uri.path, Rutas.inicio);
      expect(
        contenedor.read(gestorDeTiempoRealProvider)!.canales,
        isNot(contains('admin')),
      );
      expect(repo.ingresosConGoogle, 0);
      expect(repo.ingresosConCorreo, isEmpty);
      await tester.pumpWidget(const SizedBox());
      await repo.sesiones.close();
      await repo.fallos.close();
    },
  );
}
