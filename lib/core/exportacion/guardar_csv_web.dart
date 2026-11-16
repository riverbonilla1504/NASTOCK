import 'dart:js_interop';

import 'package:web/web.dart' as web;

Future<bool> guardarCsv(String nombre, String contenido) async {
  final archivo = web.Blob(
    <JSAny>[contenido.toJS].toJS,
    web.BlobPropertyBag(type: 'text/csv;charset=utf-8'),
  );
  final url = web.URL.createObjectURL(archivo);
  final enlace = web.HTMLAnchorElement()
    ..href = url
    ..download = nombre;
  web.document.body?.append(enlace);
  try {
    enlace.click();
    return true;
  } finally {
    enlace.remove();
    Future<void>.delayed(const Duration(seconds: 1), () {
      web.URL.revokeObjectURL(url);
    });
  }
}
