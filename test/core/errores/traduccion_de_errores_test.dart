import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:inversiones/core/errores/codigos_de_error.dart';
import 'package:inversiones/core/errores/traduccion_de_errores.dart';
import 'package:supabase_flutter/supabase_flutter.dart'
    show AuthException, PostgrestException;

/// Líneas de un archivo de `docs/` (la prueba corre desde la raíz del proyecto).
List<String> _lineasDeDocs(String archivo) =>
    File('docs/$archivo').readAsStringSync().split(RegExp(r'\r?\n'));

void main() {
  group('Catálogo de 06 §9 (texto literal de la documentación)', () {
    const esperados = <String, String>{
      'SESION_INVALIDA': 'Tu sesión no es válida. Vuelve a ingresar.',
      'NO_AUTORIZADO': 'No tienes permiso para esta acción.',
      'NO_EXISTE': 'Lo que buscas ya no existe.',
      'ESTADO_INVALIDO':
          'Esta operación ya cambió de estado. Actualiza la pantalla.',
      'YA_DECIDIDA':
          'Ya registraste una decisión distinta sobre esta sugerencia.',
      'VENCIDA': 'La sugerencia venció.',
      'FUERA_DE_BANDA':
          'El precio se movió más de lo permitido desde la sugerencia.',
      'FUERA_DE_VENTANA':
          'No se abren compras tan cerca de la apertura o del cierre.',
      'FONDOS_INSUFICIENTES': 'No tienes disponible suficiente.',
      'DATO_DESACTUALIZADO':
          'El precio no está actualizado. Intenta en unos segundos.',
      'TRADING_PAUSADO': 'La operación está pausada por el administrador.',
      'IA_PAUSADA': 'El agente de IA está pausado.',
      'INTEGRACION_CAIDA':
          'El broker o los datos de mercado no están disponibles.',
      'MISMO_ANALISTA': 'La segunda aprobación debe hacerla otro analista.',
      'ULTIMO_ADMIN': 'Debe quedar al menos un administrador activo.',
      'AUTO_ACCION': 'No puedes aplicarte esta acción a ti mismo.',
      'CUPO_CON_POSICIONES': 'El cupo tiene posiciones u órdenes abiertas.',
      'INVITACION_DUPLICADA':
          'Ya existe una invitación vigente para ese correo.',
      'CORREO_YA_REGISTRADO': 'Ese correo ya tiene una cuenta.',
      'CUPO_SUPERA_MAXIMO': 'El cupo supera el máximo permitido por persona.',
      'FONDO_SIN_CAPITAL': 'Fondo sin capital.',
    };

    for (final entrada in esperados.entries) {
      test('${entrada.key} tiene su mensaje en español', () {
        expect(traducirCodigo(entrada.key), entrada.value);
      });
    }

    test('MERCADO_CERRADO sin hora de apertura', () {
      expect(traducirCodigo('MERCADO_CERRADO'), 'El mercado está cerrado.');
    });

    test(
      'MERCADO_CERRADO con la apertura en UTC la muestra en hora de Bogotá',
      () {
        expect(
          traducirCodigo('MERCADO_CERRADO', detalle: '2026-11-05T14:30:00Z'),
          'El mercado está cerrado. Abre a las 09:30.',
        );
      },
    );

    test('MERCADO_CERRADO ignora un detalle que no es una hora', () {
      final mensaje = traducirCodigo(
        'MERCADO_CERRADO',
        detalle: 'cualquier texto crudo',
      );
      expect(mensaje, 'El mercado está cerrado.');
    });

    test('PARAMETRO_FUERA_DE_RANGO', () {
      expect(
        traducirCodigo('PARAMETRO_FUERA_DE_RANGO'),
        'El valor está fuera del rango permitido.',
      );
    });

    test('todo código de la tabla de 06 §9 está en el catálogo de la app', () {
      final codigos = <String>{};
      for (final linea in _lineasDeDocs('06-modelo-de-datos.md')) {
        final fila = RegExp(r'^\| `([A-Z][A-Za-z0-9_]*)` \|').firstMatch(linea);
        if (fila != null) codigos.add(fila.group(1)!);
      }
      // 06 §9 tiene 23 códigos más `REGLA_RR_xx`; si cambia, esta prueba avisa.
      expect(codigos, contains('REGLA_RR_xx'));
      expect(codigos.length, greaterThanOrEqualTo(24));

      for (final codigo in codigos.where((c) => c != 'REGLA_RR_xx')) {
        expect(
          mensajesPorCodigo,
          contains(codigo),
          reason: '06 §9 define $codigo y la app no lo traduce',
        );
        expect(traducirCodigo(codigo), isNot(mensajeGenerico));
      }
    });
  });

  group('REGLA_RR_xx (texto de la regla violada, 02 §9)', () {
    test('las 22 reglas de 02 §9 están y coinciden con la documentación', () {
      final reglasDeLaDocumentacion = <String, String>{};
      for (final linea in _lineasDeDocs('02-logica-de-negocio.md')) {
        final fila = RegExp(r'^\| \*\*(RR-\d{2})\*\* \| (.+?) \| ')
            .firstMatch(linea);
        if (fila == null) continue;
        reglasDeLaDocumentacion[fila.group(1)!] = fila
            .group(2)!
            .replaceAllMapped(RegExp(r'\[([^\]]*)\]\([^)]*\)'), (m) => m[1]!)
            .replaceAll('`', '')
            .replaceAll('**', '');
      }

      expect(reglasDeLaDocumentacion.length, 22);
      expect(reglasDeRiesgo, reglasDeLaDocumentacion);
    });

    test('REGLA_RR_05 dice qué regla se violó', () {
      final mensaje = traducirCodigo('REGLA_RR_05');
      expect(mensaje, startsWith('No se cumple la regla RR-05.'));
      expect(mensaje, contains('Concentración'));
    });

    test('una regla que la app aún no conoce da un mensaje propio', () {
      expect(
        traducirCodigo('REGLA_RR_99'),
        'No se cumple la regla de riesgo RR-99.',
      );
    });

    test('un código mal formado no es una regla', () {
      expect(traducirCodigo('REGLA_RR_5'), mensajeGenerico);
      expect(traducirCodigo('REGLA_RR_005'), mensajeGenerico);
    });
  });

  group('Un código desconocido muestra el mensaje genérico', () {
    test('código fuera del catálogo', () {
      expect(traducirCodigo('NO_ESTA_EN_EL_CATALOGO'), mensajeGenerico);
    });

    test('código nulo o vacío', () {
      expect(traducirCodigo(null), mensajeGenerico);
      expect(traducirCodigo(''), mensajeGenerico);
    });

    test('el mensaje genérico está en español', () {
      expect(
        mensajeGenerico,
        'Ocurrió un error inesperado. Inténtalo de nuevo.',
      );
    });
  });

  group('traducirError', () {
    test('una RPC que falla con un código del catálogo', () {
      const error = PostgrestException(message: 'NO_AUTORIZADO', code: 'P0001');
      expect(traducirError(error), 'No tienes permiso para esta acción.');
    });

    test('tolera espacios alrededor del código', () {
      const error = PostgrestException(message: ' VENCIDA \n');
      expect(traducirError(error), 'La sugerencia venció.');
    });

    test('lleva el DETAIL de MERCADO_CERRADO', () {
      const error = PostgrestException(
        message: 'MERCADO_CERRADO',
        details: '2026-11-05T14:30:00Z',
      );
      expect(
        traducirError(error),
        'El mercado está cerrado. Abre a las 09:30.',
      );
    });

    test('un ErrorDeNegocio se traduce por su código', () {
      expect(
        traducirError(const ErrorDeNegocio('ULTIMO_ADMIN')),
        'Debe quedar al menos un administrador activo.',
      );
    });

    test('el texto crudo de Postgres nunca se muestra', () {
      const crudo = 'relation "public.cupos" does not exist';
      const error = PostgrestException(message: crudo, code: '42P01');
      final mensaje = traducirError(error);
      expect(mensaje, mensajeGenerico);
      expect(mensaje, isNot(contains('relation')));
    });

    test('un código desconocido con forma de código tampoco se muestra', () {
      const error = PostgrestException(message: 'CODIGO_NUEVO_SIN_MENSAJE');
      final mensaje = traducirError(error);
      expect(mensaje, mensajeGenerico);
      expect(mensaje, isNot(contains('CODIGO_NUEVO_SIN_MENSAJE')));
    });

    test('otras excepciones muestran el mensaje genérico, no su texto', () {
      expect(
        traducirError(Exception('SocketException: sin red')),
        mensajeGenerico,
      );
      expect(traducirError(StateError('estado raro')), mensajeGenerico);
      expect(
        traducirError(const AuthException('Invalid login')),
        mensajeGenerico,
      );
      expect(traducirError('NO_AUTORIZADO'), mensajeGenerico);
      expect(traducirError(null), mensajeGenerico);
    });
  });
}
