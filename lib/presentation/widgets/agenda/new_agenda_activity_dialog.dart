import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:flutter/material.dart';

class NewAgendaActivityDialog extends StatefulWidget {
  final DateTime initialDate;

  const NewAgendaActivityDialog({super.key, required this.initialDate});

  @override
  State<NewAgendaActivityDialog> createState() =>
      _NewAgendaActivityDialogState();
}

class _NewAgendaActivityDialogState extends State<NewAgendaActivityDialog> {
  static const _types = [
    'Visita presencial',
    'Llamada',
    'Seguimiento',
    'Tarea',
  ];
  static const _prospects = ['Ninguno', 'Alan Dorantes'];
  static const _locations = ['Lote', 'Oficina', 'Videollamada', 'Otro'];
  static const _reminders = [0, 5, 15, 30, 60];

  final _descriptionController = TextEditingController();
  String _type = _types.first;
  String _prospect = _prospects.first;
  AgendaStatus _status = AgendaStatus.pending;
  String _location = _locations.first;
  int _reminder = 15;
  late DateTime _date = DateUtils.dateOnly(widget.initialDate);
  TimeOfDay _time = const TimeOfDay(hour: 12, minute: 30);

  @override
  void dispose() {
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (selected != null && mounted) setState(() => _date = selected);
  }

  Future<void> _selectTime() async {
    final selected = await showTimePicker(context: context, initialTime: _time);
    if (selected != null && mounted) setState(() => _time = selected);
  }

  void _save() {
    Navigator.pop(
      context,
      AgendaActivity(
        title: _type.toUpperCase(),
        prospect: _prospect == 'Ninguno'
            ? 'SIN PROSPECTO'
            : _prospect.toUpperCase(),
        description: _descriptionController.text.trim(),
        date: DateTime(
          _date.year,
          _date.month,
          _date.day,
          _time.hour,
          _time.minute,
        ),
        status: _status,
        location: _location.toUpperCase(),
        reminderMinutes: _reminder,
      ),
    );
  }

  String get _dateLabel =>
      '${_date.day.toString().padLeft(2, '0')}/${_date.month.toString().padLeft(2, '0')}/${_date.year}';

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 0, 22, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Nueva actividad',
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
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded, size: 30),
                  ),
                ],
              ),
              _AgendaDropdown<String>(
                label: 'Tipo',
                value: _type,
                items: _types,
                itemLabel: (value) => value,
                onChanged: (value) => setState(() => _type = value),
              ),
              _AgendaDropdown<String>(
                label: 'Prospecto',
                value: _prospect,
                items: _prospects,
                itemLabel: (value) => value,
                onChanged: (value) => setState(() => _prospect = value),
              ),
              _AgendaDropdown<AgendaStatus>(
                label: 'Estado',
                value: _status,
                items: AgendaStatus.values,
                itemLabel: (value) =>
                    value.label[0] + value.label.substring(1).toLowerCase(),
                onChanged: (value) => setState(() => _status = value),
              ),
              _AgendaDropdown<String>(
                label: 'Lugar',
                value: _location,
                items: _locations,
                itemLabel: (value) => value,
                onChanged: (value) => setState(() => _location = value),
              ),
              const _FieldLabel('Fecha/hora'),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _PickerButton(label: _dateLabel, onPressed: _selectDate),
                  _PickerButton(
                    label: _time.format(context),
                    onPressed: _selectTime,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _AgendaDropdown<int>(
                label: 'Recordatorio',
                value: _reminder,
                items: _reminders,
                itemLabel: (value) =>
                    value == 0 ? 'Sin recordatorio' : '$value minutos antes',
                onChanged: (value) => setState(() => _reminder = value),
              ),
              const _FieldLabel('Descripción'),
              TextField(
                key: const ValueKey('new-activity-description'),
                controller: _descriptionController,
                minLines: 2,
                maxLines: 4,
                style: const TextStyle(fontFamily: 'SulphurPoint'),
                decoration: _fieldDecoration,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _DialogButton(
                      label: 'CANCELAR',
                      color: const Color(0xFF696969),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: _DialogButton(
                      key: const ValueKey('save-new-activity'),
                      label: 'GUARDAR',
                      color: const Color(0xFF008FA0),
                      onPressed: _save,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
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

  const _AgendaDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.itemLabel,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      _FieldLabel(label),
      DropdownButtonFormField<T>(
        isExpanded: true,
        initialValue: value,
        dropdownColor: AppColors.primaryColor,
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
  final VoidCallback onPressed;
  const _PickerButton({required this.label, required this.onPressed});

  @override
  Widget build(BuildContext context) => FilledButton(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primaryColor,
      foregroundColor: AppColors.homeBackground,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
    ),
    onPressed: onPressed,
    child: Text(label),
  );
}

class _DialogButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback onPressed;

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(7)),
    ),
    onPressed: onPressed,
    child: Text(label, style: const TextStyle(fontFamily: 'BebasNeue')),
  );
}
