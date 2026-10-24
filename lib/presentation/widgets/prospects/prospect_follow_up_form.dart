import 'package:callerapp_frontend/presentation/screens/screens.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_call_information.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class _FollowUpActivityDraft {
  const _FollowUpActivityDraft({
    required this.date,
    required this.medium,
    required this.reminderMinutes,
    required this.description,
  });

  final DateTime date;
  final String medium;
  final int reminderMinutes;
  final String description;
}

class ProspectFollowUpForm extends StatefulWidget {
  final ProspectRecord prospect;
  final ValueChanged<String> onSaved;
  final ProspectsService? prospectsService;
  final ProspectsRepository? repository;
  final bool telephoneCallCompleted;
  final AgendaActivity? sourceActivity;
  final Future<List<AgendaActivity>> Function()? loadActivities;
  final ValueChanged<AgendaActivity>? onOpenActivity;
  const ProspectFollowUpForm({
    super.key,
    required this.prospect,
    required this.onSaved,
    this.prospectsService,
    this.repository,
    this.telephoneCallCompleted = false,
    this.sourceActivity,
    this.loadActivities,
    this.onOpenActivity,
  });
  @override
  State<ProspectFollowUpForm> createState() => _ProspectFollowUpFormState();
}

class _ProspectFollowUpFormState extends State<ProspectFollowUpForm> {
  final _notes = TextEditingController();
  final _activityDescription = TextEditingController();
  final _activityForm = GlobalKey<FormState>();
  late final ProspectsService _service;
  late final ProspectsRepository _repository;
  late final AgendaService _agendaService;
  String _status = 'Nuevo';
  late String _method;
  late String _priority = widget.prospect.temperature;
  bool _success = false;
  late bool _schedule;
  late DateTime _activityDate;
  late TimeOfDay _activityTime;
  String _activityMedium = 'llamada';
  int _reminderMinutes = 15;
  _FollowUpActivityDraft? _activityDraft;
  bool _saving = false;
  bool _loadingContext = true;
  bool _completionAcknowledged = false;
  String? _error;
  String? _contextError;
  List<AgendaActivity> _activeActivities = [];
  Map<String, dynamic>? _saved;

  bool get _requiresCompletedCall =>
      widget.sourceActivity?.isFollowUp == true &&
      !widget.telephoneCallCompleted;

  void _showCallRequiredNotice() => setState(() {
    _error = 'Primero debes realizar una llamada.';
  });

  @override
  void initState() {
    super.initState();
    _service = widget.prospectsService ?? ProspectsService();
    _repository = widget.repository ?? ProspectsRepository(service: _service);
    _agendaService = AgendaService();
    _method = widget.telephoneCallCompleted ? 'Llamada telefónica' : 'WhatsApp';
    if (widget.sourceActivity?.medium != null) {
      _method = _methodForActivity(widget.sourceActivity!.medium!);
    }
    final initial =
        widget.prospect.nextContact ??
        businessNow().add(const Duration(days: 1));
    _activityDate = DateUtils.dateOnly(initial);
    _activityTime = TimeOfDay.fromDateTime(initial);
    _schedule = false;
    _completionAcknowledged = widget.prospect.id == null;
    _loadActivityContext();
  }

  @override
  void dispose() {
    _notes.dispose();
    _activityDescription.dispose();
    if (widget.prospectsService == null) _service.dispose();
    if (widget.repository == null) _repository.dispose();
    _agendaService.dispose();
    super.dispose();
  }

  Future<void> _loadActivityContext() async {
    if (widget.prospect.id == null) {
      if (mounted) setState(() => _loadingContext = false);
      return;
    }
    try {
      final activities =
          await (widget.loadActivities?.call() ?? _agendaService.fetch());
      if (!mounted) return;
      final active = activities
          .where(
            (activity) =>
                activity.prospectId == widget.prospect.id &&
                (activity.status == AgendaStatus.pending ||
                    activity.status == AgendaStatus.overdue),
          )
          .toList();
      setState(() {
        _activeActivities = active;
        _loadingContext = false;
        final followUp = _followUpToComplete;
        if (followUp?.medium != null) {
          _method = _methodForActivity(followUp!.medium!);
        }
      });
    } on AgendaException catch (error) {
      if (mounted) {
        if (widget.sourceActivity != null) {
          setState(() {
            _activeActivities = [widget.sourceActivity!];
            _loadingContext = false;
          });
          return;
        }
        setState(() {
          _contextError = error.message;
          _loadingContext = false;
        });
      }
    }
  }

  AgendaActivity? get _followUpToComplete {
    final source = widget.sourceActivity;
    if (source != null && source.isFollowUp) return source;
    for (final activity in _activeActivities) {
      if (activity.isFollowUp) return activity;
    }
    return null;
  }

  List<AgendaActivity> get _otherActiveActivities => _activeActivities
      .where(
        (activity) =>
            !activity.isFollowUp && activity.id != widget.sourceActivity?.id,
      )
      .toList();

  String _methodForActivity(String medium) => switch (medium) {
    'llamada' => 'Llamada telefónica',
    'whatsapp' => 'WhatsApp',
    'facebook' => 'Facebook',
    'correo' => 'Correo',
    _ => medium,
  };

  void _cancel() => setState(() {
    _status = _saved?['status'] ?? 'Nuevo';
    _method =
        _saved?['method'] ??
        (widget.telephoneCallCompleted ? 'Llamada telefónica' : 'WhatsApp');
    _priority = _saved?['priority'] ?? widget.prospect.temperature;
    _notes.text = _saved?['notes'] ?? '';
    _success = _saved?['success'] ?? false;
    _schedule = _saved?['schedule'] ?? false;
    _activityDraft = _saved?['activity'] as _FollowUpActivityDraft?;
  });

  Future<void> _pickDate() async {
    final now = businessNow();
    final date = await showDatePicker(
      context: context,
      initialDate: _activityDate.isBefore(DateUtils.dateOnly(now))
          ? DateUtils.dateOnly(now)
          : _activityDate,
      firstDate: DateUtils.dateOnly(now),
      lastDate: DateTime(now.year + 5),
    );
    if (!mounted || date == null) return;
    setState(() {
      _activityDate = date;
      _activityDraft = null;
    });
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _activityTime,
    );
    if (!mounted || time == null) return;
    setState(() {
      _activityTime = time;
      _activityDraft = null;
    });
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
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: AppPalette.of(context).textColor,
          ),
        ),
        const SizedBox(height: 3),
        child,
      ],
    ),
  );
  Widget _select(
    String label,
    String value,
    List<String> values,
    ValueChanged<String> change, {
    bool enabled = true,
  }) => _label(
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
      onChanged: enabled ? (v) => setState(() => change(v!)) : null,
    ),
  );
  Widget _toggle(String label, bool value, ValueChanged<bool> onChanged) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 5),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  color: AppPalette.of(context).textColor,
                ),
              ),
            ),
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
                    child: Icon(
                      value ? Icons.check : Icons.close,
                      size: 17,
                      color: AppColors.textDarkColor,
                    ),
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

  Widget _lockedField(String label, String value) => _label(
    label,
    Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF398FA3).withValues(alpha: .78),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(value, style: const TextStyle(color: Colors.white)),
          ),
          const Icon(Icons.lock_outline, color: Colors.white70, size: 18),
        ],
      ),
    ),
  );

  DateTime get _scheduledActivity => DateTime(
    _activityDate.year,
    _activityDate.month,
    _activityDate.day,
    _activityTime.hour,
    _activityTime.minute,
  );

  void _saveActivityDraft() {
    if (!_activityForm.currentState!.validate()) return;
    final scheduled = _scheduledActivity;
    if (!scheduled.isAfter(businessNow())) {
      setState(() => _error = 'Selecciona una fecha y hora futuras.');
      return;
    }
    setState(() {
      _error = null;
      _activityDraft = _FollowUpActivityDraft(
        date: scheduled,
        medium: _activityMedium,
        reminderMinutes: _reminderMinutes,
        description: _activityDescription.text.trim(),
      );
    });
  }

  Future<void> _saveFollowUp() async {
    if (_saving) return;
    if (_loadingContext || _contextError != null) {
      setState(
        () => _error = 'No se pudo validar la actividad que será completada.',
      );
      return;
    }
    if (!_completionAcknowledged) {
      setState(
        () => _error = 'Confirma el aviso de la actividad antes de guardar.',
      );
      return;
    }
    if (_schedule && _activityDraft == null) {
      setState(
        () => _error = 'Guarda primero los datos de la siguiente actividad.',
      );
      return;
    }
    if (widget.prospect.id == null) {
      _saved = {
        'status': _status,
        'method': _method,
        'priority': _priority,
        'notes': _notes.text,
        'success': _success,
        'schedule': _schedule,
        'activity': _activityDraft,
      };
      widget.onSaved(
        '$_status · $_method${_notes.text.trim().isEmpty ? '' : ' · ${_notes.text.trim()}'}',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seguimiento guardado en esta vista.')),
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final contactMedium = switch (_method) {
      'Correo' => 'correo',
      'WhatsApp' => 'whatsapp',
      'Facebook' => 'facebook',
      _ => 'telefono',
    };
    final priority = switch (_priority) {
      'Frío' => 'frio',
      'Tibio' => 'tibio',
      _ => 'caliente',
    };
    try {
      final activity = _schedule ? _activityDraft : null;
      final fields = <String, dynamic>{
        'estatus': _status,
        'prioridad': priority,
        'medio': contactMedium,
        'nota': _notes.text.trim(),
        'hubo_exito': _success,
        if (widget.sourceActivity?.id != null)
          'actividad_origen_id': widget.sourceActivity!.id,
        if (activity != null)
          'actividad': {
            'tipo': 'seguimiento',
            'prospecto_id': widget.prospect.id,
            'medio': activity.medium,
            'descripcion': activity.description,
            'programada_at': businessTimeToUtcIso8601(activity.date),
            'recordatorio_at': businessTimeToUtcIso8601(
              activity.date.subtract(
                Duration(minutes: activity.reminderMinutes),
              ),
            ),
          },
      };
      final result =
          widget.repository == null && widget.prospectsService != null
          ? null
          : await _repository.createFollowUp(widget.prospect, fields);
      if (result == null) {
        await _service.createFollowUp(widget.prospect.id!, fields);
      }
      _saved = {
        'status': _status,
        'method': _method,
        'priority': _priority,
        'notes': _notes.text,
        'success': _success,
        'schedule': _schedule,
        'activity': _activityDraft,
      };
      widget.onSaved(
        '$_status · $_method${_notes.text.trim().isEmpty ? '' : ' · ${_notes.text.trim()}'}',
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              result?.isPending == true
                  ? 'Seguimiento guardado. Se sincronizará cuando haya conexión.'
                  : activity == null
                  ? 'Seguimiento guardado.'
                  : 'Seguimiento y siguiente actividad guardados.',
            ),
          ),
        );
      }
    } on ProspectsException catch (error) {
      if (mounted) setState(() => _error = error.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Widget _activityEditor() => Form(
    key: _activityForm,
    child: Container(
      key: const ValueKey('follow-up-activity-form'),
      margin: const EdgeInsets.only(top: 6, bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 199, 247, 255),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _lockedField('Tipo', 'Seguimiento'),
          _lockedField('Prospecto', widget.prospect.name),
          _select(
            'Medio de contacto',
            _activityMedium,
            const ['llamada', 'whatsapp', 'facebook', 'correo'],
            (value) {
              _activityMedium = value;
              _activityDraft = null;
            },
          ),
          _label(
            'Fecha y hora',
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                _scheduleButton(_dateLabel(_activityDate), _pickDate),
                _scheduleButton(_activityTime.format(context), _pickTime),
              ],
            ),
          ),
          _select(
            'Recordatorio',
            _reminderMinutes.toString(),
            const ['5', '15', '30', '60'],
            (value) {
              _reminderMinutes = int.parse(value);
              _activityDraft = null;
            },
          ),
          _label(
            'Descripción',
            TextFormField(
              key: const ValueKey('follow-up-activity-description'),
              controller: _activityDescription,
              minLines: 2,
              maxLines: 4,
              style: const TextStyle(color: Colors.white),
              decoration: _decoration(),
              onChanged: (_) => setState(() => _activityDraft = null),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'La descripción es obligatoria'
                  : null,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: FilledButton(
              key: const ValueKey('save-follow-up-activity'),
              onPressed: _saveActivityDraft,
              child: const Text('GUARDAR ACTIVIDAD'),
            ),
          ),
        ],
      ),
    ),
  );

  Widget _activitySummary(_FollowUpActivityDraft activity) => Container(
    key: const ValueKey('follow-up-activity-summary'),
    width: double.infinity,
    margin: const EdgeInsets.only(top: 6, bottom: 8),
    padding: const EdgeInsets.all(10),
    decoration: BoxDecoration(
      color: const Color(0xFF398FA3),
      borderRadius: BorderRadius.circular(10),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Seguimiento · ${widget.prospect.name}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          '${_dateLabel(activity.date)} · ${TimeOfDay.fromDateTime(activity.date).format(context)} · ${activity.medium}',
          style: const TextStyle(color: Colors.white),
        ),
        Text(activity.description, style: const TextStyle(color: Colors.white)),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            key: const ValueKey('edit-follow-up-activity'),
            onPressed: () => setState(() => _activityDraft = null),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('EDITAR'),
          ),
        ),
      ],
    ),
  );

  Widget _activityContextNotice() {
    if (_loadingContext) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      );
    }
    if (_contextError != null) {
      return Container(
        margin: const EdgeInsets.only(top: 6, bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: AppPalette.of(context).errorSurfaceFill,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          children: [
            Text(_contextError!),
            TextButton(
              onPressed: () {
                setState(() {
                  _loadingContext = true;
                  _contextError = null;
                });
                _loadActivityContext();
              },
              child: const Text('REINTENTAR'),
            ),
          ],
        ),
      );
    }
    final activity = _followUpToComplete;
    final message = activity == null
        ? 'No existe una actividad de seguimiento programada. Al guardar, el sistema creará una nueva actividad en estado Completado.'
        : widget.sourceActivity?.id == activity.id
        ? 'Este seguimiento quedará vinculado a la actividad abierta desde Agenda y la marcará como Completada.'
        : 'Al guardar se completará el seguimiento programado para el ${_dateLabel(activity.date)} a las ${TimeOfDay.fromDateTime(activity.date).format(context)}.';
    return Container(
      key: const ValueKey('follow-up-completion-notice'),
      width: double.infinity,
      margin: const EdgeInsets.only(top: 6, bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color.fromARGB(255, 28, 99, 111),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(message, style: TextStyle(color: AppColors.whiteColor,)),
          const SizedBox(height: 6),
          Wrap(
            alignment: WrapAlignment.start,
            spacing: 8,
            runSpacing: 6,
            children: [
              if (activity != null && widget.onOpenActivity != null)
                FilledButton.icon(
                  key: const ValueKey('open-follow-up-completion-activity'),
                  onPressed: () => widget.onOpenActivity!(activity),
                  style: FilledButton.styleFrom(
                    backgroundColor:const Color.fromARGB(255, 21, 93, 226),
                    foregroundColor: AppColors.whiteColor,
                  ),
                  icon: const Icon(Iconsax.document_text_copy),
                  label: const Text('VER ACTIVIDAD'),
                ),
              FilledButton.icon(
                key: const ValueKey('acknowledge-follow-up-completion'),
                onPressed: _completionAcknowledged
                    ? null
                    : () => setState(() {
                        _completionAcknowledged = true;
                        _error = null;
                      }),
                style: FilledButton.styleFrom(
                  backgroundColor: _completionAcknowledged
                      ? const Color.fromARGB(255, 90, 125, 195)
                      : const Color.fromARGB(255, 22, 163, 224),
                ),
                icon: Icon(
                  _completionAcknowledged
                      ? Iconsax.tick_circle
                      : Icons.info_outline,
                  color: _completionAcknowledged
                      ? Color.fromARGB(255, 170, 237, 255)
                      : Colors.white,
                ),
                label: Text(
                  _completionAcknowledged ? 'CONFIRMADO' : 'ENTENDIDO',
                  style: TextStyle(
                    color: _completionAcknowledged
                        ? Color.fromARGB(255, 170, 237, 255)
                        : Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _otherActivityNotice(AgendaActivity activity) => InkWell(
    key: ValueKey('other-active-activity-${activity.id}'),
    onTap: widget.onOpenActivity == null
        ? null
        : () => widget.onOpenActivity!(activity),
    borderRadius: BorderRadius.circular(10),
    child: Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppPalette.of(context).noticeSurfaceFill,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          Icon(
            Icons.info_outline,
            color: AppPalette.of(context).noticeSurfaceInk,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Existe otra actividad pendiente: ${activity.title} · ${_dateLabel(activity.date)} ${TimeOfDay.fromDateTime(activity.date).format(context)}. No se modificará al guardar.',
            ),
          ),
          if (widget.onOpenActivity != null)
            Icon(
              Icons.chevron_right,
              color: AppPalette.of(context).noticeSurfaceInk,
            ),
        ],
      ),
    ),
  );

  @override
  Widget build(BuildContext context) => Column(
    children: [
      ProspectDetailPanel(
        initiallyExpanded: true,
        nested: true,
        color: const Color.fromARGB(255, 33, 117, 140),
        title: 'Acerca del seguimiento',
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppPalette.of(context).nestedSurfaceFill,
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
              _select(
                '¿Cómo intentaste contactarlo?',
                _method,
                [
                  if (widget.telephoneCallCompleted ||
                      _method == 'Llamada telefónica')
                    'Llamada telefónica',
                  'WhatsApp',
                  'Facebook',
                  'Correo',
                ],
                (v) => _method = v,
                enabled: _followUpToComplete?.medium == null,
              ),
              _select('Prioridad del prospecto', _priority, [
                'Caliente',
                'Tibio',
                'Frío',
              ], (v) => _priority = v),
              const SizedBox(height: 6),
              _toggle(
                '¿Hubo éxito en el contacto?',
                _success,
                (v) => setState(() => _success = v),
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
              const SizedBox(height: 6),
              _toggle(
                '¿Programar siguiente contacto?',
                _schedule,
                (v) => setState(() {
                  _schedule = v;
                  _error = null;
                }),
              ),
              if (_schedule && _activityDraft == null) _activityEditor(),
              if (_schedule && _activityDraft != null)
                _activitySummary(_activityDraft!),
              _activityContextNotice(),
              for (final activity in _otherActiveActivities)
                _otherActivityNotice(activity),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    _error!,
                    key: const ValueKey('follow-up-save-error'),
                    style: TextStyle(
                      color: AppPalette.of(context).fieldErrorInk,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFFA34D4D),
                        foregroundColor: Colors.white,
                      ),
                      onPressed: _saving ? null : _cancel,
                      child: const Text('CANCELAR'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Semantics(
                      button: true,
                      enabled: !_requiresCompletedCall && !_saving,
                      child: GestureDetector(
                        key: const ValueKey('follow-up-save-area'),
                        behavior: HitTestBehavior.opaque,
                        onTap: _requiresCompletedCall
                            ? _showCallRequiredNotice
                            : null,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4CA382),
                            foregroundColor: Colors.white,
                          ),
                          onPressed: _saving || _requiresCompletedCall
                              ? null
                              : _saveFollowUp,
                          child: Text(_saving ? 'GUARDANDO…' : 'GUARDAR'),
                        ),
                      ),
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
