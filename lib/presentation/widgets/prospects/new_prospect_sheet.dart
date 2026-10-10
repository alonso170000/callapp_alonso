import 'package:flutter/material.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/presentation/validators/prospect_validators.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class NewProspectSheet extends StatefulWidget {
  const NewProspectSheet({super.key, this.service});
  final ProspectsService? service;

  @override
  State<NewProspectSheet> createState() => _NewProspectSheetState();
}

class _NewProspectSheetState extends State<NewProspectSheet> {
  final _form = GlobalKey<FormState>();
  final _fields = <String, TextEditingController>{
    for (final name in [
      'Nombre',
      'Email',
      'Ciudad',
      'Teléfono',
      'Empresa donde trabaja',
      'Ocupación',
      'Comentarios acerca del prospecto',
    ])
      name: TextEditingController(),
  };
  final _qualification = <String, bool>{
    'Decisión': false,
    'Disposición': false,
    'Dinero': false,
    'Pasó a TO': false,
  };
  late final ProspectsService _service;
  List<Map<String, dynamic>> _origins = [], _statuses = [];
  int? _origin, _status;
  bool _loading = true, _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    _service = widget.service ?? ProspectsService();
    _loadCatalogs();
  }

  Future<void> _loadCatalogs() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final catalogs = await Future.wait([
        _service.catalog('canales'),
        _service.catalog('estatus-prospecto'),
      ]);
      if (!mounted) return;
      if (catalogs.any((items) => items.isEmpty)) {
        throw const ProspectsException(
          'No hay orígenes o estatus disponibles.',
        );
      }
      setState(() {
        _origins = catalogs[0];
        _statuses = catalogs[1];
        _origin = _origins.first['id'] as int;
        _status =
            (_statuses
                        .where(
                          (s) =>
                              (s['nombre'] as String).toLowerCase() == 'nuevo',
                        )
                        .firstOrNull ??
                    _statuses.first)['id']
                as int;
      });
    } on ProspectsException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    for (final controller in _fields.values) {
      controller.dispose();
    }
    if (widget.service == null) _service.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving ||
        _origin == null ||
        _status == null ||
        !_form.currentState!.validate()) {
      return;
    }
    String text(String name) => _fields[name]!.text.trim();
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _service.create({
        'nombre': text('Nombre'),
        'correo': text('Email'),
        'telefono_normalizado': text('Teléfono').replaceAll(RegExp(r'\D'), ''),
        'ciudad': text('Ciudad'),
        'nombre_compania': text('Empresa donde trabaja'),
        'ocupacion': text('Ocupación'),
        'comentario': text('Comentarios acerca del prospecto'),
        'canal_id': _origin,
        'estatus_id': _status,
        'calificacion': [
          if (_qualification['Decisión']!) 'decision',
          if (_qualification['Disposición']!) 'disposicion',
          if (_qualification['Dinero']!) 'dinero',
          if (_qualification['Pasó a TO']!) 'paso_to',
        ],
      });
      if (mounted) Navigator.pop(context, true);
    } on ProspectsException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  InputDecoration _decoration(String label) => const InputDecoration(
    filled: true,
    fillColor: AppColors.primaryColor,
    contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.all(Radius.circular(9)),
      borderSide: BorderSide.none,
    ),
    errorMaxLines: 2,
    prefixStyle: TextStyle(color: AppColors.homeBackground),
  );

  Widget _labeled(String label, {required Widget child}) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 10, bottom: 4),
        child: Text(label, style: const TextStyle(fontFamily: 'SulphurPoint')),
      ),
      child,
    ],
  );
  Widget _field(
    String name, {
    bool required = false,
    bool numeric = false,
    int lines = 1,
  }) => _labeled(
    '$name${required ? '*' : ''}',
    child: TextFormField(
      key: ValueKey('prospect-$name'),
      controller: _fields[name],
      style: const TextStyle(
        fontFamily: 'SulphurPoint',
        fontSize: 16,
        color: AppColors.homeBackground,
      ),
      cursorColor: AppColors.homeBackground,
      minLines: lines,
      maxLines: lines,
      keyboardType: numeric
          ? const TextInputType.numberWithOptions(decimal: true)
          : name == 'Email'
          ? TextInputType.emailAddress
          : name == 'Teléfono'
          ? TextInputType.phone
          : lines > 1
          ? TextInputType.multiline
          : TextInputType.text,
      decoration: _decoration(
        '$name${required ? ' *' : ''}',
      ).copyWith(prefixText: name == 'Precio completo del lote' ? '\$ ' : null),
      validator: numeric
          ? ProspectValidators.number
          : name == 'Email'
          ? ProspectValidators.email
          : name == 'Teléfono'
          ? ProspectValidators.phone
          : required
          ? ProspectValidators.requiredText
          : null,
    ),
  );

  Widget _heading(String title) => Padding(
    padding: const EdgeInsets.only(top: 20, bottom: 2),
    child: Text(
      title,
      style: const TextStyle(
        fontFamily: 'SulphurPoint',
        fontSize: 16,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  Widget _dropdown<T>(
    String label,
    T value,
    List<T> values,
    ValueChanged<T> change, {
    String Function(T)? format,
  }) => _labeled(
    label,
    child: DropdownButtonFormField<T>(
      isExpanded: true,
      initialValue: value,
      dropdownColor: AppColors.primaryColor,
      borderRadius: BorderRadius.circular(9),
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: AppColors.homeBackground,
      ),
      style: const TextStyle(
        fontFamily: 'SulphurPoint',
        fontSize: 16,
        color: AppColors.homeBackground,
      ),
      decoration: _decoration(label),
      items: values
          .map(
            (item) => DropdownMenuItem(
              value: item,
              child: Text(
                format?.call(item) ?? '$item',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => change(value));
      },
    ),
  );

  @override
  Widget build(BuildContext context) => Padding(
    padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
    child: SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Row(
              children: [
                const SizedBox(width: 48),
                const Expanded(
                  child: Text(
                    'Nuevo prospecto',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SulphurPoint',
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar',
                  onPressed: _saving ? null : () => Navigator.pop(context),
                  icon: const Icon(Icons.close_rounded, size: 30),
                ),
              ],
            ),
          ),
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(22, 8, 22, 12),
              child: Form(
                key: _form,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heading('Información del Contacto'),
                    for (final name in [
                      'Nombre',
                      'Email',
                      'Ciudad',
                      'Teléfono',
                    ])
                      _field(name, required: true),
                    _field('Empresa donde trabaja'),
                    _field('Ocupación'),
                    _heading('Origen y Estado'),
                    if (_loading) const LinearProgressIndicator(),
                    if (_origins.isNotEmpty && _statuses.isNotEmpty) ...[
                      _dropdown<int>(
                        'Origen*',
                        _origin!,
                        _origins.map((v) => v['id'] as int).toList(),
                        (v) => _origin = v,
                        format: (id) =>
                            _origins.firstWhere((v) => v['id'] == id)['nombre']
                                as String,
                      ),
                      _dropdown<int>(
                        'Status*',
                        _status!,
                        _statuses.map((v) => v['id'] as int).toList(),
                        (v) => _status = v,
                        format: (id) =>
                            _statuses.firstWhere((v) => v['id'] == id)['nombre']
                                as String,
                      ),
                    ],
                    if (_error != null) ...[
                      Text(_error!, style: const TextStyle(color: Colors.red)),
                      if (_origins.isEmpty)
                        TextButton(
                          onPressed: _loadCatalogs,
                          child: const Text('Reintentar'),
                        ),
                    ],
                    _heading('Califica tu lead'),
                    for (final label in _qualification.keys)
                      _QualificationToggle(
                        label: label,
                        value: _qualification[label]!,
                        onChanged: (value) =>
                            setState(() => _qualification[label] = value),
                      ),
                    const SizedBox(height: 16),
                    _field('Comentarios acerca del prospecto', lines: 3),
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: AppColors.homeBackground,
              border: Border(
                top: BorderSide(
                  color: AppColors.primaryColor.withValues(alpha: 0.12),
                ),
              ),
            ),
            padding: const EdgeInsets.fromLTRB(22, 8, 22, 16),
            child: Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF696969),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      textStyle: const TextStyle(fontFamily: 'BebasNeue'),
                    ),
                    onPressed: _saving ? null : () => Navigator.pop(context),
                    child: const Text('Cancelar'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    key: const ValueKey('save-prospect'),
                    onPressed: _saving || _loading || _origin == null
                        ? null
                        : _save,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF008FA0),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(7),
                      ),
                      textStyle: const TextStyle(fontFamily: 'BebasNeue'),
                    ),
                    child: Text(_saving ? 'Guardando…' : 'Guardar'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

class _QualificationToggle extends StatelessWidget {
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;
  const _QualificationToggle({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Semantics(
    label: label,
    toggled: value,
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => onChanged(!value),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontFamily: 'SulphurPoint',
                    fontSize: 16,
                    color: AppColors.primaryColor,
                  ),
                ),
              ),
              SizedBox(
                width: 56,
                height: 48,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 22,
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      color: value
                          ? const Color(0xFF4EA58B)
                          : const Color(0xFFA94E52),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 180),
                      alignment: value
                          ? Alignment.centerRight
                          : Alignment.centerLeft,
                      child: Container(
                        width: 20,
                        height: 16,
                        decoration: BoxDecoration(
                          color: value
                              ? const Color(0xFFADFADE)
                              : const Color(0xFFF7AAAA),
                          borderRadius: BorderRadius.circular(3),
                        ),
                        child: Icon(
                          value ? Icons.check_rounded : Icons.close_rounded,
                          size: 16,
                          color: value
                              ? AppColors.primaryColor
                              : const Color(0xFF802B30),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
