/// Una alerta visible por RLS (HU-085, docs/06 §5.5).
class Alerta {
  const Alerta({
    required this.id,
    required this.titulo,
    required this.cuerpo,
    required this.severidad,
    required this.creadaEn,
    this.version = 1,
  });

  factory Alerta.desdeJson(Map<String, dynamic> json) => Alerta(
    id: json['id'] as String,
    titulo: json['titulo'] as String,
    cuerpo: json['cuerpo'] as String,
    severidad: json['severidad'] as String,
    creadaEn: DateTime.parse(json['creado_en'] as String),
    version: json['version'] as int? ?? 1,
  );
  final String id;
  final String titulo;
  final String cuerpo;
  final String severidad;
  final DateTime creadaEn;
  final int version;
}
