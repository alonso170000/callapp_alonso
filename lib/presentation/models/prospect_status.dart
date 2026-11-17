class ProspectStatus {
  const ProspectStatus._();

  static const workflow = <String>[
    'Nuevo',
    'Contactado y validado',
    'Seguimiento',
    'Cotización',
    'Negociación',
    'Venta realizada',
  ];

  static String canonical(String value) {
    final trimmed = value.trim();
    return switch (_key(trimmed)) {
      'nuevo' => 'Nuevo',
      'validado' || 'contactado y validado' => 'Contactado y validado',
      'seguimiento' => 'Seguimiento',
      'cotizacion' => 'Cotización',
      'negociacion' => 'Negociación',
      'venta realizada' => 'Venta realizada',
      _ => trimmed,
    };
  }

  static String followUpInitial(String value) {
    final status = canonical(value);
    return workflow.contains(status) ? status : workflow.first;
  }

  static String databaseValue(String value) => switch (canonical(value)) {
    'Contactado y validado' => 'Validado',
    'Cotización' => 'Cotizacion',
    'Negociación' => 'Negociacion',
    final status => status,
  };

  static List<String> availableFrom(String value) {
    final status = followUpInitial(value);
    return workflow.sublist(workflow.indexOf(status));
  }

  static String _key(String value) => value
      .trim()
      .toLowerCase()
      .replaceAll('á', 'a')
      .replaceAll('é', 'e')
      .replaceAll('í', 'i')
      .replaceAll('ó', 'o')
      .replaceAll('ú', 'u');
}
