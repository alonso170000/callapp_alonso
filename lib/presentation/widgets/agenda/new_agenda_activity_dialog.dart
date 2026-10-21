import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:flutter/material.dart';

class NewAgendaActivityDialog extends StatefulWidget {
  final DateTime initialDate;
  final AgendaActivity? activity;
  final AgendaService? agendaService;
  final ProspectsService? prospectsService;
  const NewAgendaActivityDialog({
    super.key,
    required this.initialDate,
    this.activity,
    this.agendaService,
    this.prospectsService,
  });
  @override
  State<NewAgendaActivityDialog> createState() =>
      _NewAgendaActivityDialogState();
}

class _NewAgendaActivityDialogState extends State<NewAgendaActivityDialog> {
  final _form = GlobalKey<FormState>();
  final _descriptionController = TextEditingController();
  late final AgendaService _agenda;
  late final ProspectsService _prospectsService;
  List<ProspectRecord> _prospects = [];
  String _type = 'seguimiento', _medium = 'llamada', _location = 'Lote';
  int _prospect = 0, _reminder = 15;
  bool _loading = true, _saving = false;
  String? _error;
  late DateTime _date;
  late TimeOfDay _time;

  @override
  void initState() {
    super.initState();
    _agenda = widget.agendaService ?? AgendaService();
    _prospectsService = widget.prospectsService ?? ProspectsService();
    final activity = widget.activity;
    if (activity != null) {
      _type = activity.type?.replaceAll(' ', '_') ?? 'tarea';
      _medium = activity.medium ?? 'llamada';
      _location = activity.location;
      _prospect = activity.prospectId ?? 0;
      _reminder = activity.reminderMinutes == 0 ? 15 : activity.reminderMinutes;
      _descriptionController.text = activity.description == 'Sin descripción'
          ? ''
          : activity.description;
      _date = DateUtils.dateOnly(activity.date);
      _time = TimeOfDay.fromDateTime(activity.date);
      _loadProspects();
      return;
    }
    final now = businessNow();
    final next = DateTime(
      now.year,
      now.month,
      now.day,
      now.hour,
      now.minute + 1,
    );
    _date = widget.initialDate.isAfter(next)
        ? DateUtils.dateOnly(widget.initialDate)
        : DateUtils.dateOnly(next);
    _time = TimeOfDay.fromDateTime(next);
    _loadProspects();
  }

  Future<void> _loadProspects() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final prospects = await _prospectsService.fetch();
      if (mounted) {
        setState(
          () => _prospects = prospects.where((p) => p.id != null).toList(),
        );
      }
    } on ProspectsException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _descriptionController.dispose();
    if (widget.agendaService == null) _agenda.dispose();
    if (widget.prospectsService == null) _prospectsService.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final today = DateUtils.dateOnly(businessNow());
    final selected = await showDatePicker(
      context: context,
      initialDate: _date.isBefore(today) ? today : _date,
      firstDate: today,
      lastDate: DateTime(today.year + 5),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(
      context: context,
      initialTime: _time,
      initialEntryMode: TimePickerEntryMode.input,
      helpText: 'Hora de la actividad (24 h)',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (selected != null && mounted) setState(() => _time = selected);
  }

  String _prospectLabel(int id) {
    if (id == 0) return 'Sin prospecto';
    for (final prospect in _prospects) {
      if (prospect.id == id) return prospect.name;
    }
    return widget.activity?.prospect ?? 'Prospecto';
  }

  Future<void> _save() async {
    if (_saving || !_form.currentState!.validate()) return;
    final scheduled = DateTime(
      _date.year,
      _date.month,
      _date.day,
      _time.hour,
      _time.minute,
    );
    if (!scheduled.isAfter(businessNow())) {
      setState(
        () => _error = 'Puedes agendar hoy. Selecciona un minuto posterior a la hora actual.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      final fields = <String, dynamic>{
        'tipo': _type,
        'prospecto_id': _prospect == 0 ? null : _prospect,
        'programada_at': businessTimeToUtcIso8601(scheduled),
        'recordatorio_at': businessTimeToUtcIso8601(
          scheduled.subtract(Duration(minutes: _reminder)),
        ),
        if (_descriptionController.text.trim().isNotEmpty)
          'descripcion': _descriptionController.text.trim(),
        if (_type == 'seguimiento') 'medio': _medium,
        if (_type == 'visita_presencial') 'ubicacion': _location,
      };
      final activityId = widget.activity?.id;
      if (activityId == null) {
        await _agenda.create(fields);
      } else {
        await _agenda.update(activityId, fields);
      }
      if (mounted) {
        setState(() => _saving = false);
        // Allow PopScope to rebuild before closing the successful form.
        await WidgetsBinding.instance.endOfFrame;
        if (mounted) Navigator.pop(context, scheduled);
      }
    } on AgendaException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_saving,
    child: Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          child: Form(
            key: _form,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const SizedBox(width: 48),
                    Expanded(
                      child: Text(
                        widget.activity == null
                            ? 'Nueva actividad'
                            : 'Editar actividad',
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
                if (_loading) const LinearProgressIndicator(),
                if (_error != null) ...[
                  Text(
                    _error!,
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  if (_prospects.isEmpty)
                    TextButton(
                      onPressed: _saving ? null : _loadProspects,
                      child: const Text('Reintentar carga de prospectos'),
                    ),
                ],
                AbsorbPointer(
                  absorbing: _saving,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _AgendaDropdown<String>(
                        label: 'Tipo*',
                        value: _type,
                        items: const [
                          'seguimiento',
                          'visita_presencial',
                          'tarea',
                        ],
                        itemLabel: (v) => switch (v) {
                          'seguimiento' => 'Seguimiento',
                          'visita_presencial' => 'Visita presencial',
                          _ => 'Tarea',
                        },
                        onChanged: (v) => setState(() => _type = v),
                      ),
                      _AgendaDropdown<int>(
                        label: _type == 'tarea'
                            ? 'Prospecto (opcional)'
                            : 'Prospecto*',
                        value: _prospect,
                        items: {
                          0,
                          if (_prospect != 0) _prospect,
                          ..._prospects.map((p) => p.id!),
                        }.toList(),
                        itemLabel: _prospectLabel,
                        validator: (id) =>
                            _type != 'tarea' && (id == null || id == 0)
                            ? 'Selecciona un prospecto'
                            : null,
                        onChanged: (v) => setState(() => _prospect = v),
                      ),
                      if (_type == 'seguimiento')
                        _AgendaDropdown<String>(
                          label: 'Medio de contacto*',
                          value: _medium,
                          items: const [
                            'llamada',
                            'whatsapp',
                            'facebook',
                            'correo',
                          ],
                          itemLabel: (v) => switch (v) {
                            'llamada' => 'Llamada',
                            'whatsapp' => 'WhatsApp',
                            'facebook' => 'Facebook',
                            _ => 'Correo',
                          },
                          onChanged: (v) => setState(() => _medium = v),
                        ),
                      if (_type == 'visita_presencial')
                        _AgendaDropdown<String>(
                          label: 'Lugar*',
                          value: _location,
                          items: const ['Lote', 'Oficina', 'Otro'],
                          itemLabel: (v) => v,
                          onChanged: (v) => setState(() => _location = v),
                        ),
                      const _FieldLabel('Fecha y hora*'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _PickerButton(
                            label:
                                '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}',
                            onPressed: _selectDate,
                          ),
                          _PickerButton(
                            label:
                                '${_time.hour.toString().padLeft(2, '0')}:${_time.minute.toString().padLeft(2, '0')}',
                            onPressed: _selectTime,
                          ),
                        ],
                      ),
                      _AgendaDropdown<int>(
                        label: 'Recordatorio*',
                        value: _reminder,
                        items: const [5, 15, 30, 60],
                        itemLabel: (v) => '$v minutos antes',
                        onChanged: (v) => setState(() => _reminder = v),
                      ),
                      _FieldLabel(
                        _type == 'visita_presencial'
                            ? 'Descripción'
                            : 'Descripción*',
                      ),
                      TextFormField(
                        key: const ValueKey('new-activity-description'),
                        controller: _descriptionController,
                        minLines: 2,
                        maxLines: 4,
                        style: const TextStyle(
                          fontFamily: 'SulphurPoint',
                          color: AppColors.homeBackground,
                        ),
                        decoration: _fieldDecoration,
                        validator: (v) =>
                            _type != 'visita_presencial' &&
                                (v == null || v.trim().isEmpty)
                            ? 'La descripción es obligatoria'
                            : null,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _DialogButton(
                        label: 'CANCELAR',
                        color: const Color(0xFF696969),
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _DialogButton(
                        key: ValueKey(
                          widget.activity == null
                              ? 'save-new-activity'
                              : 'save-edited-activity',
                        ),
                        label: _saving ? 'GUARDANDO…' : 'GUARDAR',
                        color: const Color(0xFF008FA0),
                        onPressed: _saving ? null : _save,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

const _fieldDecoration = InputDecoration(
  filled: true,
  fillColor: AppColors.primaryColor,
  contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 9),
  border: OutlineInputBorder(
    borderRadius: BorderRadius.all(Radius.circular(9)),
    borderSide: BorderSide.none,
  ),
);

class _FieldLabel extends StatelessWidget {
  final String text;
  const _FieldLabel(this.text);

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 10, bottom: 4),
    child: Text(text, style: const TextStyle(fontFamily: 'SulphurPoint')),
  );
}

class _AgendaDropdown<T> extends StatelessWidget {
  final String label;
  final T value;
  final List<T> items;
  final String Function(T) itemLabel;
  final ValueChanged<T> onChanged;
  final FormFieldValidator<T>? validator;

  const _AgendaDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
    this.validator,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _FieldLabel(label),
      DropdownButtonFormField<T>(
        isExpanded: true,
        initialValue: value,
        validator: validator,
        dropdownColor: AppColors.primaryColor,
        icon: const Icon(Icons.keyboard_arrow_down_rounded),
        iconEnabledColor: AppColors.homeBackground,
        style: const TextStyle(
          color: AppColors.homeBackground,
          fontFamily: 'SulphurPoint',
          fontSize: 16,
        ),
        decoration: _fieldDecoration,
        items: items
            .map(
              (item) => DropdownMenuItem(
                value: item,
                child: Text(
                  itemLabel(item),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            )
            .toList(),
        onChanged: (item) {
          if (item != null) onChanged(item);
        },
      ),
    ],
  );
}

class _PickerButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  const _PickerButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.homeBackground,
      padding: EdgeInsets.symmetric(horizontal: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
    onPressed: onPressed,
    child: Text(
      label,
      style: const TextStyle(fontFamily: 'SulphurPoint', fontSize: 20),
    ),
  );
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onPressed;

  const _DialogButton({
    super.key,
    required this.label,
    required this.color,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: color,
      foregroundColor: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: 4),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    ),
    onPressed: onPressed,
    child: Text(
      label,
      style: const TextStyle(fontFamily: 'BebasNeue', fontSize: 18),
    ),
  );
}
