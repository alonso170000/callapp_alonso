int _requiredInt(Object? value, String field) {
  final parsed = value is int ? value : int.tryParse('$value');
  if (parsed == null) throw FormatException('Falta $field');
  return parsed;
}

int? _optionalInt(Object? value) =>
    value == null ? null : int.tryParse('$value');

String _requiredText(Object? value, String field) {
  final text = value?.toString();
  if (text == null || text.trim().isEmpty) {
    throw FormatException('Falta $field');
  }
  return text;
}

class GuionesBundle {
  const GuionesBundle({this.version, this.fetchedAt, required this.guiones});
  final String? version;
  final DateTime? fetchedAt;
  final List<Guion> guiones;

  factory GuionesBundle.fromJson(
    Map<String, dynamic> json, {
    DateTime? fetchedAt,
  }) {
    final raw = json['guiones'];
    if (raw is! List) throw const FormatException('Faltan guiones');
    return GuionesBundle(
      version: json['version']?.toString(),
      fetchedAt: fetchedAt,
      guiones: raw
          .map((item) => Guion.fromJson(Map<String, dynamic>.from(item as Map)))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'version': version,
    'guiones': guiones.map((item) => item.toJson()).toList(),
  };
}

class Guion {
  const Guion({
    required this.id,
    required this.codigo,
    required this.titulo,
    this.subtitulo,
    this.tipoProspecto,
    required this.orden,
    required this.pasos,
  });
  final int id;
  final String codigo;
  final String titulo;
  final String? subtitulo;
  final String? tipoProspecto;
  final int orden;
  final List<GuionPaso> pasos;

  GuionPaso? get pasoInicial {
    for (final paso in pasos) {
      if (paso.esInicial) return paso;
    }
    return pasos.isEmpty ? null : pasos.first;
  }

  GuionPaso? pasoPorId(int id) {
    for (final paso in pasos) {
      if (paso.id == id) return paso;
    }
    return null;
  }

  factory Guion.fromJson(Map<String, dynamic> json) {
    final raw = json['pasos'];
    if (raw is! List) throw const FormatException('Faltan pasos');
    return Guion(
      id: _requiredInt(json['id'], 'id'),
      codigo: _requiredText(json['codigo'], 'codigo'),
      titulo: _requiredText(json['titulo'], 'titulo'),
      subtitulo: json['subtitulo']?.toString(),
      tipoProspecto: json['tipo_prospecto']?.toString(),
      orden: _optionalInt(json['orden']) ?? 1,
      pasos: raw
          .map(
            (item) =>
                GuionPaso.fromJson(Map<String, dynamic>.from(item as Map)),
          )
          .toList(),
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'codigo': codigo,
    'titulo': titulo,
    'subtitulo': subtitulo,
    'tipo_prospecto': tipoProspecto,
    'orden': orden,
    'pasos': pasos.map((item) => item.toJson()).toList(),
  };
}

class GuionPaso {
  const GuionPaso({
    required this.id,
    required this.codigo,
    required this.titulo,
    required this.contenido,
    this.notaAsesor,
    this.notaPosicion = 'despues',
    this.vinetas = const [],
    this.siguientePasoId,
    this.esInicial = false,
    this.orden = 1,
    this.opciones = const [],
  });
  final int id;
  final String codigo;
  final String titulo;
  final String contenido;
  final String? notaAsesor;
  final String notaPosicion;
  final List<String> vinetas;
  final int? siguientePasoId;
  final bool esInicial;
  final int orden;
  final List<GuionOpcion> opciones;
  factory GuionPaso.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['opciones'];
    final rawBullets = json['vinetas'];
    return GuionPaso(
      id: _requiredInt(json['id'], 'id de paso'),
      codigo: _requiredText(json['codigo'], 'código de paso'),
      titulo: _requiredText(json['titulo'], 'título de paso'),
      contenido: _requiredText(json['contenido'], 'contenido'),
      notaAsesor: json['nota_asesor']?.toString(),
      notaPosicion: json['nota_posicion']?.toString() == 'antes'
          ? 'antes'
          : 'despues',
      vinetas: rawBullets is List
          ? rawBullets
                .where((item) => item != null)
                .map((item) => item.toString())
                .toList()
          : const [],
      siguientePasoId: _optionalInt(json['siguiente_paso_id']),
      esInicial: json['es_inicial'] == true || json['es_inicial'] == 1,
      orden: _optionalInt(json['orden']) ?? 1,
      opciones: rawOptions is List
          ? rawOptions
                .map(
                  (item) => GuionOpcion.fromJson(
                    Map<String, dynamic>.from(item as Map),
                  ),
                )
                .toList()
          : const [],
    );
  }
  Map<String, dynamic> toJson() => {
    'id': id,
    'codigo': codigo,
    'titulo': titulo,
    'contenido': contenido,
    'nota_asesor': notaAsesor,
    'nota_posicion': notaPosicion,
    'vinetas': vinetas,
    'siguiente_paso_id': siguientePasoId,
    'es_inicial': esInicial,
    'orden': orden,
    'opciones': opciones.map((item) => item.toJson()).toList(),
  };
}

class GuionOpcion {
  const GuionOpcion({
    required this.id,
    required this.etiqueta,
    required this.siguientePasoId,
    this.icono,
    this.orden = 1,
  });
  final int id;
  final String etiqueta;
  final int siguientePasoId;
  final String? icono;
  final int orden;
  factory GuionOpcion.fromJson(Map<String, dynamic> json) => GuionOpcion(
    id: _requiredInt(json['id'], 'id de opción'),
    etiqueta: _requiredText(json['etiqueta'], 'etiqueta'),
    siguientePasoId: _requiredInt(
      json['siguiente_paso_id'],
      'siguiente paso de opción',
    ),
    icono: json['icono']?.toString(),
    orden: _optionalInt(json['orden']) ?? 1,
  );
  Map<String, dynamic> toJson() => {
    'id': id,
    'etiqueta': etiqueta,
    'siguiente_paso_id': siguientePasoId,
    'icono': icono,
    'orden': orden,
  };
}
