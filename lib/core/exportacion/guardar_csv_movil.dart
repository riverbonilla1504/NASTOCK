import 'package:flutter/services.dart';

Future<bool> guardarCsv(String nombre, String contenido) async {
  const canal = MethodChannel('inversiones/exportacion');
  return await canal.invokeMethod<bool>('guardarCsv', {
        'nombre': nombre,
        'contenido': contenido,
      }) ??
      false;
}
