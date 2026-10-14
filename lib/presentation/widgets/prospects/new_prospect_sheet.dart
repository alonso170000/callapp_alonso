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
      'Descripción del primer seguimiento',
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
  List<Map<String, dynamic>> _lots = [];
  int? _origin, _status;
  int _lot = 0;
  String _priority = 'caliente';
  bool _firstFollowUp = false;
  String _activityType = 'seguimiento';
  String _contactMedium = 'llamada';
  String _location = 'Lote';
  int _reminderMinutes = 15;
  DateTime _activityDate = DateUtils.dateOnly(
    DateTime.now().add(const Duration(days: 1)),
  );
  TimeOfDay _activityTime = const TimeOfDay(hour: 12, minute: 30);
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
        _service.availableLots(),
      ]);
      if (!mounted) return;
      if (catalogs[0].isEmpty || catalogs[1].isEmpty) {
        throw const ProspectsException(
          'No hay orígenes o estatus disponibles.',
        );
      }
      if (_service.activeDevelopment?['id'] is! int) {
        throw const ProspectsException(
          'No hay un desarrollo activo en la sesión.',
        );
      }
      setState(() {
        _origins = catalogs[0];
        _statuses = catalogs[1];
        _lots = catalogs[2];
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
      final scheduledAt = DateTime(
        _activityDate.year,
        _activityDate.month,
        _activityDate.day,
        _activityTime.hour,
        _activityTime.minute,
      );
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
        'prioridad': _priority,
        if (_lot != 0) 'lote_id': _lot,
        if (_firstFollowUp)
          'primer_seguimiento': {
            'tipo': _activityType,
            'programada_at': scheduledAt.toIso8601String(),
            'recordatorio_at': scheduledAt
                .subtract(Duration(minutes: _reminderMinutes))
                .toIso8601String(),
            if (_activityType != 'visita_presencial' ||
                text('Descripción del primer seguimiento').isNotEmpty)
              'descripcion': text('Descripción del primer seguimiento'),
            if (_activityType == 'visita_presencial')
              'ubicacion': _location == 'Lote' && _lot != 0
                  ? 'Lote ${_lotLabel(_lot)}'
                  : _location,
            if (_activityType == 'seguimiento') 'medio': _contactMedium,
          },
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

  Widget _dateTimeButton(String label, VoidCallback onPressed) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.homeBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
    onPressed: onPressed,
    child: Text(label),
  );

  String _lotLabel(int id) =>
      '${_lots.firstWhere((lot) => lot['id'] == id)['numero_lote']}';

  Future<void> _selectActivityDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _activityDate,
      firstDate: DateUtils.dateOnly(DateTime.now()),
      lastDate: DateTime.now().add(const Duration(days: 3650)),
    );
    if (mounted && selected != null) setState(() => _activityDate = selected);
  }

  Future<void> _selectActivityTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _activityTime,
    );
    if (mounted && selected != null) setState(() => _activityTime = selected);
  }

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
                    if (_loading)
                      LinearProgressIndicator(
                        color: AppColors.primaryColor,
                        backgroundColor: Theme.of(context).colorScheme.surface,
                      ),
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
                      _dropdown<String>(
                        'Prioridad*',
                        _priority,
                        const ['caliente', 'tibio', 'frio'],
                        (value) => _priority = value,
                        format: (value) => switch (value) {
                          'caliente' => 'Caliente',
                          'tibio' => 'Tibio',
                          'frio' => 'Frío',
                          _ => value,
                        },
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
                    _heading('Información de interés'),
                    if (_service.activeDevelopment?['id'] is int)
                      _dropdown<int>(
                        'Desarrollo*',
                        _service.activeDevelopment!['id'] as int,
                        [_service.activeDevelopment!['id'] as int],
                        (_) {},
                        format: (_) =>
                            _service.activeDevelopment!['nombre']?.toString() ??
                            'Desarrollo activo',
                      ),
                    _dropdown<int>(
                      'Lote',
                      _lot,
                      [0, ..._lots.map((lot) => lot['id'] as int)],
                      (value) => _lot = value,
                      format: (id) => id == 0
                          ? 'Sin lote seleccionado'
                          : 'Lote ${_lotLabel(id)}',
                    ),
                    KeyedSubtree(
                      key: const ValueKey('first-follow-up'),
                      child: _dropdown<bool>(
                        'Primer seguimiento',
                        _firstFollowUp,
                        const [false, true],
                        (value) => _firstFollowUp = value,
                        format: (value) =>
                            value ? 'Sí, agregar seguimiento' : 'No, por ahora',
                      ),
                    ),
                    if (_firstFollowUp) ...[
                      _dropdown<String>(
                        'Tipo*',
                        _activityType,
                        const ['seguimiento', 'visita_presencial', 'tarea'],
                        (value) => _activityType = value,
                        format: (value) => switch (value) {
                          'seguimiento' => 'Seguimiento',
                          'visita_presencial' => 'Visita presencial',
                          'tarea' => 'Tarea',
                          _ => value,
                        },
                      ),
                      if (_activityType == 'seguimiento')
                        _dropdown<String>(
                          'Medio de contacto*',
                          _contactMedium,
                          const ['llamada', 'whatsapp', 'facebook', 'correo'],
                          (value) => _contactMedium = value,
                          format: (value) => switch (value) {
                            'llamada' => 'Llamada',
                            'whatsapp' => 'WhatsApp',
                            'facebook' => 'Facebook',
                            'correo' => 'Correo',
                            _ => value,
                          },
                        ),
                      if (_activityType == 'visita_presencial')
                        _dropdown<String>('Lugar*', _location, const [
                          'Lote',
                          'Oficina',
                          'Otro',
                        ], (value) => _location = value),
                      _labeled(
                        'Fecha y hora*',
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            _dateTimeButton(
                              '${_activityDate.day.toString().padLeft(2, '0')}/${_activityDate.month.toString().padLeft(2, '0')}/${_activityDate.year}',
                              _selectActivityDate,
                            ),
                            _dateTimeButton(
                              _activityTime.format(context),
                              _selectActivityTime,
                            ),
                          ],
                        ),
                      ),
                      _dropdown<int>(
                        'Recordatorio*',
                        _reminderMinutes,
                        const [5, 15, 30, 60],
                        (value) => _reminderMinutes = value,
                        format: (value) => '$value minutos antes',
                      ),
                      _field(
                        'Descripción del primer seguimiento',
                        required: _activityType != 'visita_presencial',
                        lines: 3,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
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
          padding: const EdgeInsets.symmetric(vertical: 0),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontFamily: 'SulphurPoint',
                    fontSize: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
              SizedBox(
                width: 56,
                height: 48,
                child: Center(
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 52,
                    height: 28,
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: value
                          ? const Color(0xFF4EA58B)
                          : const Color(0xFFA94E52),
                      borderRadius: BorderRadius.circular(6),
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
