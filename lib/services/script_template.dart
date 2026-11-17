final _scriptVariable = RegExp(r'\{[a-zA-Z_][a-zA-Z0-9_]*\}');

String renderScriptText(
  String text, {
  required String nombre,
  required String asesor,
  String? desarrollo,
  Map<String, String> extra = const {},
}) {
  final values = <String, String>{
    'nombre': nombre,
    'prospectName': nombre,
    'asesor': asesor,
    'desarrollo': ?desarrollo,
    ...extra,
  };
  return text.replaceAllMapped(
    _scriptVariable,
    (match) =>
        values[match.group(0)!.substring(1, match.group(0)!.length - 1)] ??
        match.group(0)!,
  );
}

bool hasUnresolvedVariables(String text) => _scriptVariable.hasMatch(text);
