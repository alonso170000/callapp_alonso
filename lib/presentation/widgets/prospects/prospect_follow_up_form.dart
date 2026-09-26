import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_call_information.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';

class ProspectFollowUpForm extends StatefulWidget {
  final ProspectRecord prospect;
  final ValueChanged<String> onSaved;
  const ProspectFollowUpForm({
    super.key,
    required this.prospect,
    required this.onSaved,
  });
  @override
  State<ProspectFollowUpForm> createState() => _ProspectFollowUpFormState();
}

class _ProspectFollowUpFormState extends State<ProspectFollowUpForm> {
  final _origin = TextEditingController(text: 'Campaña FB');
  final _notes = TextEditingController();
  String _status = 'Nuevo';
  String _method = 'Llamada telefónica';
  late String _priority = widget.prospect.temperature;
  bool _success = false;
  late bool _schedule;
  late DateTime? _next;
  Map<String, dynamic>? _saved;

  @override
  void initState() {
    super.initState();
    _next = widget.prospect.nextContact;
    _schedule = _next != null;
  }

  @override
  void dispose() {
    _origin.dispose();
    _notes.dispose();
    super.dispose();
  }

  void _cancel() => setState(() {
    _status = _saved?['status'] ?? 'Nuevo';
    _method = _saved?['method'] ?? 'Llamada telefónica';
    _priority = _saved?['priority'] ?? widget.prospect.temperature;
    _origin.text = _saved?['origin'] ?? 'Campaña FB';
    _notes.text = _saved?['notes'] ?? '';
    _success = _saved?['success'] ?? false;
    _schedule = _saved?['schedule'] ?? widget.prospect.nextContact != null;
    _next = _saved?['next'] ?? widget.prospect.nextContact;
  });

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final date = await showDatePicker(
      context: context,
      initialDate: _next ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5),
    );
    if (!mounted || date == null) return;
    final current = _next ?? now;
    setState(
      () => _next = DateTime(
        date.year,
        date.month,
        date.day,
        current.hour,
        current.minute,
      ),
    );
  }

  Future<void> _pickTime() async {
    final now = DateTime.now();
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_next ?? now),
    );
    if (!mounted || time == null) return;
    setState(
      () => _next = DateTime(
        (_next ?? now).year,
        (_next ?? now).month,
        (_next ?? now).day,
        time.hour,
        time.minute,
      ),
    );
  }

  String _dateLabel(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/'
      '${value.month.toString().padLeft(2, '0')}/${value.year}';

  InputDecoration _decoration() => InputDecoration(
    filled: true,
    fillColor: const Color(0xFF398FA3),
    isDense: true,
    contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(8),
      borderSide: BorderSide.none,
    ),
  );
  Widget _label(String label, Widget child) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 13)),
        const SizedBox(height: 3),
        child,
      ],
    ),
  );
  Widget _select(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> change,
  ) => _label(
    label,
    DropdownButtonFormField<String>(
      key: ValueKey('$label$value'),
      initialValue: value,
      isExpanded: true,
      style: const TextStyle(
        fontFamily: 'SulphurPoint',
        color: Colors.white,
        fontSize: 16,
      ),
      dropdownColor: const Color(0xFF398FA3),
      icon: const Icon(Icons.keyboard_arrow_down, color: Colors.white),
      decoration: _decoration(),
      items: values
          .map((v) => DropdownMenuItem(value: v, child: Text(v)))
          .toList(),
      onChanged: (v) => setState(() => change(v!)),
    ),
  );
  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            Expanded(child: Text(label, style: const TextStyle(fontSize: 13))),
            Semantics(
              toggled: value,
              label: label,
              child: InkWell(
                onTap: () => onChanged(!value),
                child: Container(
                  width: 62,
                  height: 27,
                  alignment: value
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: value
                        ? const Color(0xFF4CA382)
                        : const Color(0xFFA44D4D),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Container(
                    width: 27,
                    decoration: BoxDecoration(
                      color: value
                          ? const Color(0xFFA8F7D3)
                          : const Color(0xFFFFB1B1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Icon(value ? Icons.check : Icons.close, size: 17),
                  ),
                ),
              ),
            ),
          ],
        ),
      );

  Widget _scheduleButton(String label, VoidCallback onPressed) => TextButton(
    style: TextButton.styleFrom(
      backgroundColor: const Color(0xFF398FA3),
      foregroundColor: Colors.white,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      textStyle: const TextStyle(fontFamily: 'SulphurPoint', fontSize: 17),
    ),
    onPressed: onPressed,
    child: Text(label),
  );
  @override
  Widget build(BuildContext context) => Column(
    children: [
      ProspectDetailPanel(
        initiallyExpanded: true,
        nested: true,
        color: const Color(0xFF195768),
        title: 'Acerca del seguimiento',
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFB2EFFA),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Column(
            children: [
              _select('Estatus de seguimiento', _status, [
                'Nuevo',
                'Seguimiento',
                'Contactado y validado',
                'Cotización',
                'Negociación',
                'Venta realizada',
              ], (v) => _status = v),
              _label(
                'Origen del prospecto',
                TextField(
                  controller: _origin,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration(),
                ),
              ),
              _select('¿Cómo intentaste contactarlo?', _method, [
                'Llamada telefónica',
                'Mensaje',
                'Correo',
              ], (v) => _method = v),
              _select('Prioridad del prospecto', _priority, [
                'Caliente',
                'Tibio',
                'Frío',
              ], (v) => _priority = v),
              _toggle(
                '¿Hubo éxito en el contacto?',
                _success,
                (v) => setState(() => _success = v),
              ),
              _toggle(
                '¿Programar siguiente contacto?',
                _schedule,
                (v) => setState(() => _schedule = v),
              ),
              if (_schedule)
                Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _scheduleButton(
                        _next == null
                            ? 'Seleccionar fecha'
                            : _dateLabel(_next!),
                        _pickDate,
                      ),
                      _scheduleButton(
                        _next == null
                            ? 'Seleccionar hora'
                            : TimeOfDay.fromDateTime(_next!).format(context),
                        _pickTime,
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
              _label(
                'Notas de la interacción',
                TextField(
                  controller: _notes,
                  minLines: 2,
                  maxLines: 5,
                  style: const TextStyle(color: Colors.white),
                  decoration: _decoration(),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFA34D4D),
                      ),
                      onPressed: _cancel,
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF4CA382),
                      ),
                      onPressed: () {
                        if (_schedule &&
                            (_next == null ||
                                !_next!.isAfter(DateTime.now()))) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Selecciona una fecha y hora futuras.',
                              ),
                            ),
                          );
                          return;
                        }
                        _saved = {
                          'status': _status,
                          'method': _method,
                          'priority': _priority,
                          'origin': _origin.text,
                          'notes': _notes.text,
                          'success': _success,
                          'schedule': _schedule,
                          'next': _next,
                        };
                        widget.onSaved(
                          '$_status · $_method${_notes.text.trim().isEmpty ? '' : ' · ${_notes.text.trim()}'}',
                        );
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Seguimiento guardado en esta vista.',
                            ),
                          ),
                        );
                      },
                      child: const Text('GUARDAR'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      const SizedBox(height: 14),
      ProspectCallInformation(prospect: widget.prospect),
    ],
  );
}
