import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/features/admin/bitacora/data/bitacora_repositorio.dart';
import 'package:inversiones/features/admin/bitacora/presentation/pagina_bitacora.dart';

void main() {
  testWidgets(
    'aplica filtros y exporta solamente los registros que coinciden',
    (tester) async {
      const canal = MethodChannel('inversiones/exportacion');
      String? archivo;
      final mensajero = tester.binding.defaultBinaryMessenger;
      mensajero.setMockMethodCallHandler(canal, (llamada) async {
        expect(llamada.method, 'guardarCsv');
        expect(llamada.arguments['nombre'], 'bitacora.csv');
        archivo = llamada.arguments['contenido'] as String;
        return true;
      });
      addTearDown(() => mensajero.setMockMethodCallHandler(canal, null));

      RegistroDeBitacora registro(int id, String accion) => (
        id: id,
        momento: DateTime.utc(2026, 11, 16, 16),
        actor: null,
        accion: accion,
        entidad: 'parametros',
        entidadId: '="texto"',
      );
      final registros = [
        registro(2, 'parametro.cambiado'),
        registro(1, 'cupo.asignado'),
      ];
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            leerBitacoraProvider.overrideWithValue(
              (filtros, {antesDe}) async => registros
                  .where(
                    (r) => filtros.accion.isEmpty || r.accion == filtros.accion,
                  )
                  .toList(),
            ),
          ],
          child: const MaterialApp(home: PaginaBitacora()),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('cupo.asignado'), findsOneWidget);
      await tester.enterText(
        find.widgetWithText(TextFormField, 'Acción'),
        'parametro.cambiado',
      );
      await tester.tap(find.text('Aplicar filtros'));
      await tester.pumpAndSettle();
      expect(find.text('cupo.asignado'), findsNothing);
      expect(
        find.widgetWithText(ListTile, 'parametro.cambiado'),
        findsOneWidget,
      );

      await tester.tap(find.text('Exportar CSV'));
      await tester.pumpAndSettle();
      expect(archivo, contains('"parametro.cambiado"'));
      expect(archivo, isNot(contains('cupo.asignado')));
      expect(archivo, contains("\"'=\"\"texto\"\"\""));
    },
  );
}
