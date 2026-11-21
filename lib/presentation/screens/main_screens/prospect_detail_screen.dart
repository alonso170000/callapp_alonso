import 'package:callerapp_frontend/presentation/widgets/app_press_bounce.dart';

import 'dart:async';

import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_type.dart';
import 'package:callerapp_frontend/presentation/models/contact_medium.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_activity_detail.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/new_agenda_activity_dialog.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_follow_up_form.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_discovery_form.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_data_form.dart';
import 'package:callerapp_frontend/presentation/models/guion_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_history_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/scripts_panel.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_history.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_comments_panel.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_email_options_sheet.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_email_history_panel.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/call_registration_bar.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_call_result_sheet.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/convert_prospect_sheet.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_deletion_request_sheet.dart';
import 'package:callerapp_frontend/presentation/models/prospect_email_models.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/repositories/agenda_repository.dart';
import 'package:callerapp_frontend/repositories/scripts_repository.dart';
import 'package:callerapp_frontend/services/scripts_service.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/phone_call_service.dart';
import 'package:callerapp_frontend/services/phone_number.dart';
import 'package:callerapp_frontend/services/contact_launcher.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/presentation/models/call_models.dart';
import 'package:callerapp_frontend/services/call_session_controller.dart';
import 'package:callerapp_frontend/services/notification_service.dart';
import 'package:callerapp_frontend/data/local/pending_operations_store.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/widgets/app_bottom_sheet.dart';

class ProspectDetailArguments {
  const ProspectDetailArguments({
    required this.prospect,
    this.sourceActivity,
    this.callStarted = false,
    this.callSuccessful = false,
    this.callId,
    this.initialContactMedium,
  });
  final ProspectRecord prospect;
  final AgendaActivity? sourceActivity;
  final bool callStarted;
  final bool callSuccessful;
  final int? callId;
  final ContactMedium? initialContactMedium;
}

class ProspectDetailScreen extends StatefulWidget {
  final ProspectRecord prospect;
  final AgendaActivity? sourceActivity;
  final Future<List<AgendaActivity>> Function()? loadActivities;
  final PhoneCallService? phoneCallService;
  final CallSessionController? callSession;
  final bool callStarted;
  final bool callSuccessful;
  final int? callId;
  final ContactMedium? initialContactMedium;
  final Future<void> Function(ProspectRecord)? showCallReminder;
  final ProspectsRepository? prospectsRepository;
  final AgendaRepository? agendaRepository;
  final ScriptsRepository? scriptsRepository;
  const ProspectDetailScreen({
    super.key,
    required this.prospect,
    this.sourceActivity,
    this.loadActivities,
    this.phoneCallService,
    this.callSession,
    this.callStarted = false,
    this.callSuccessful = false,
    this.callId,
    this.initialContactMedium,
    this.showCallReminder,
    this.prospectsRepository,
    this.agendaRepository,
    this.scriptsRepository,
  });
  @override
  State<ProspectDetailScreen> createState() => _ProspectDetailScreenState();
}

class _ProspectDetailScreenState extends State<ProspectDetailScreen>
    with WidgetsBindingObserver {
  final _commentsKey = GlobalKey<ProspectCommentsPanelState>();
  final _selected = {'Seguimiento', 'Discovery'};
  final _panelRevisions = <String, int>{};
  final _history = <String>[];
  final _emailService = ProspectsService();
  late final PhoneCallService _phoneCallService;
  late ProspectRecord _prospect;
  ContactMedium? _primaryMedium;
  bool _mediumResolved = false;
  bool _primaryMediumFromActivity = false;
  late final ProspectsRepository _prospectsRepository;
  late final bool _ownsProspectsRepository;
  late final AgendaRepository _agendaRepository;
  late final bool _ownsAgendaRepository;
  late final ScriptsRepository _scriptsRepository;
  late final bool _ownsScriptsRepository;
  GuionesBundle? _guiones;
  bool _scriptsLoading = false;
  String? _scriptsError;
  bool _scriptsOffline = false;
  int _scriptsRequestRevision = 0;
  AgendaActivity? _sourceActivity;
  AgendaActivity? _pendingReminderActivity;
  AgendaActivity? _pendingFollowUpActivity;
  bool _activityContextResolved = false;
  int _activityContextRevision = 0;
  final _dirtyForms = <ProspectSection>{};
  bool _allowDirtyPop = false;
  List<ProspectEmailHistoryEntry> _emails = const [];
  String? _emailError;
  bool _sendingEmail = false;
  bool _convertingClient = false;
  bool _requestingDeletion = false;
  bool _telephoneCallCompleted = false;
  bool _telephoneCallSuccessful = false;
  bool _callRegistered = false;
  bool _followUpSaved = false;
  bool _calling = false;
  late final CallSessionController _callSession;
  int? _lastCallId;
  int _callResultRevision = 0;
  bool _openingCallResult = false;
  bool get _viewingCompletedFollowUp =>
      _sourceActivity?.isFollowUp == true &&
      _sourceActivity?.status == AgendaStatus.completed;
  bool get _formsReadOnly => _viewingCompletedFollowUp || _followUpSaved;
  bool get _hasDirtyForms => _dirtyForms.isNotEmpty;
  String get _dirtyFormLabels => ProspectSection.values
      .where(_dirtyForms.contains)
      .map((section) => section.label)
      .join(', ');

  void _setFormDirty(ProspectSection section, bool dirty) {
    if (!mounted) return;
    setState(() {
      if (dirty) {
        _dirtyForms.add(section);
      } else {
        _dirtyForms.remove(section);
      }
    });
  }

  Widget _actionButton(
    String label,
    IconData icon,
    VoidCallback? onPressed, {
    bool busy = false,
  }) {
    final palette = AppPalette.of(context);
    return Expanded(
      child: SizedBox(
        height: 48,
        child: AppPressBounce(
          enabled: onPressed != null,
          child: IconButton.filledTonal(
            tooltip: label,
            style: IconButton.styleFrom(
              backgroundColor: palette.secondaryActionForeground.withValues(
                alpha: 0.2,
              ),
              foregroundColor: palette.secondaryActionForeground.withValues(
                alpha: 0.7,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onPressed,
            icon: busy
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon, size: 30),
          ),
        ),
      ),
    );
  }

  Widget _primaryAction(AppPalette palette) {
    final medium = _primaryMedium;
    if (!_mediumResolved) {
      return Expanded(
        flex: 2,
        child: SizedBox(
          height: 54,
          child: Semantics(
            label: 'Cargando canal de contacto',
            button: true,
            enabled: false,
            child: AppPressBounce(
              enabled: false,
              child: FilledButton(
                onPressed: null,
                child: const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            ),
          ),
        ),
      );
    }
    if (medium == null) {
      return Expanded(
        flex: 2,
        child: SizedBox(
          height: 54,
          child: AppPressBounce(
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.brandFill,
                foregroundColor: palette.onBrand,
                padding: EdgeInsets.zero,
                shape: appButtonShape(),
                textStyle: appButtonTextStyle,
              ),
              onPressed: _openProspectData,
              child: const Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Iconsax.profile_tick_copy, size: 25),
                  SizedBox(height: 2),
                  Text(
                    'Completar datos',
                    style: TextStyle(fontFamily: 'SulphurPoint', fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }
    final busy =
        (medium == ContactMedium.llamada && _calling) ||
        (medium == ContactMedium.correo && _sendingEmail);
    final enabled = !busy;
    final button = Expanded(
      flex: 2,
      child: SizedBox(
        height: 54,
        child: Semantics(
          label: '${medium.actionLabel} a ${_prospect.name}',
          button: true,
          enabled: enabled,
          child: AppPressBounce(
            enabled: enabled,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: palette.brandFill,
                foregroundColor: palette.onBrand,
                padding: EdgeInsets.zero,
                shape: appButtonShape(),
                textStyle: appButtonTextStyle,
              ),
              onPressed: enabled ? () => _runMediumAction(medium) : null,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (busy)
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  else
                    Icon(medium.icon, size: 25),
                  const SizedBox(height: 2),
                  Text(
                    medium.actionLabel,
                    style: const TextStyle(
                      fontFamily: 'SulphurPoint',
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
    return button;
  }

  @override
  void initState() {
    super.initState();
    _phoneCallService = widget.phoneCallService ?? PhoneCallService();
    _callSession = widget.callSession ?? CallSessionController.instance;
    WidgetsBinding.instance.addObserver(this);
    _prospect = widget.prospect;
    _sourceActivity = widget.sourceActivity;
    _pendingReminderActivity =
        NotificationService.shouldRemindFollowUp(_sourceActivity)
        ? _sourceActivity
        : null;
    if (_sourceActivity?.isFollowUp == true &&
        (_sourceActivity?.status == AgendaStatus.pending ||
            _sourceActivity?.status == AgendaStatus.overdue)) {
      _pendingFollowUpActivity = _sourceActivity;
      _activityContextResolved = true;
    }
    final sourceMedium = ContactMedium.parse(_sourceActivity?.medium);
    _primaryMedium = widget.callStarted ? ContactMedium.llamada : sourceMedium;
    _mediumResolved =
        widget.callStarted ||
        sourceMedium != null ||
        widget.prospect.id == null;
    _primaryMediumFromActivity = sourceMedium != null;
    _prospectsRepository = widget.prospectsRepository ?? ProspectsRepository();
    _ownsProspectsRepository = widget.prospectsRepository == null;
    _agendaRepository = widget.agendaRepository ?? AgendaRepository();
    _ownsAgendaRepository = widget.agendaRepository == null;
    _scriptsRepository = widget.scriptsRepository ?? ScriptsRepository();
    _ownsScriptsRepository = widget.scriptsRepository == null;
    unawaited(_loadScripts());
    _telephoneCallCompleted = widget.callStarted;
    _telephoneCallSuccessful = widget.callSuccessful;
    _callRegistered = widget.callStarted;
    _lastCallId = widget.callId;
    _callSession.addListener(_callSessionChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_detectCompletedCall());
    });
    if (_viewingCompletedFollowUp) {
      _selected.addAll(ProspectSection.values.map((section) => section.label));
    }
    _loadEmails();
    if (widget.initialContactMedium != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Registra el resultado del contacto y, si quieres, agenda el siguiente seguimiento.',
            ),
          ),
        );
      });
    }
  }

  void _resolvePrimaryMedium(ContactMedium? value) {
    if (_primaryMediumFromActivity) return;
    if (!mounted) return;
    setState(() {
      _primaryMedium = value;
      _mediumResolved = true;
    });
  }

  Future<void> _loadScripts({bool force = false}) async {
    final developmentId = _prospect.interestDevelopmentId;
    final revision = ++_scriptsRequestRevision;
    if (developmentId == null) {
      if (!mounted) return;
      setState(() {
        _guiones = null;
        _scriptsLoading = false;
        _scriptsError = null;
        _scriptsOffline = false;
      });
      return;
    }
    final tipoProspecto = prospectTypeEndpointValue(_prospect.tipoProspecto);
    setState(() {
      _scriptsLoading = true;
      _scriptsError = null;
    });
    GuionesBundle? cached;
    try {
      cached = await _scriptsRepository.readCache(
        developmentId: developmentId,
        tipoProspecto: tipoProspecto,
      );
      if (!mounted || revision != _scriptsRequestRevision) return;
      if (cached != null) setState(() => _guiones = cached);
      final fresh = await _scriptsRepository.refresh(
        developmentId: developmentId,
        tipoProspecto: tipoProspecto,
      );
      if (!mounted || revision != _scriptsRequestRevision) return;
      setState(() {
        _guiones = fresh;
        _scriptsOffline = false;
      });
    } on ScriptsException catch (error) {
      if (!mounted || revision != _scriptsRequestRevision) return;
      setState(() {
        if (cached != null || _guiones != null) {
          _scriptsOffline = true;
        } else {
          _scriptsError = error.message;
        }
      });
    } finally {
      if (mounted && revision == _scriptsRequestRevision) {
        setState(() => _scriptsLoading = false);
      }
    }
  }

  void _applyProspectUpdate(ProspectRecord updated) {
    final developmentChanged =
        updated.interestDevelopmentId != _prospect.interestDevelopmentId;
    setState(() {
      _prospect = updated;
      if (developmentChanged) {
        _guiones = null;
        _scriptsError = null;
        _scriptsOffline = false;
      }
    });
    if (developmentChanged) unawaited(_loadScripts());
  }

  void _pendingActivityChanged(AgendaActivity? activity) {
    if (!mounted) return;
    setState(() {
      _pendingReminderActivity = activity;
      _pendingFollowUpActivity = activity;
      _activityContextResolved = true;
    });
  }

  Future<void> _scheduleFollowUp() async {
    if (!_activityContextResolved ||
        _pendingFollowUpActivity != null ||
        _prospect.id == null) {
      return;
    }
    final scheduled = await showAppBottomSheet<DateTime>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (_) => NewAgendaActivityDialog(
        initialDate: businessNow(),
        agendaRepository: _agendaRepository,
        initialProspect: _prospect,
        lockActivityType: true,
        lockProspect: true,
      ),
    );
    if (scheduled == null || !mounted) return;
    final activity = AgendaActivity(
      prospectId: _prospect.id,
      type: 'seguimiento',
      title: 'SEGUIMIENTO',
      prospect: _prospect.name,
      description: 'Seguimiento agendado',
      date: scheduled,
      status: AgendaStatus.pending,
    );
    setState(() {
      _prospect = _prospect.copyWith(nextContact: scheduled);
      _pendingFollowUpActivity = activity;
    });
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Seguimiento agendado.')));
  }

  void _openProspectData() => setState(() {
    final label = ProspectSection.data.label;
    _selected.add(label);
    _panelRevisions[label] = (_panelRevisions[label] ?? 0) + 1;
  });

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _detectCompletedCall();
    }
  }

  Future<void> _detectCompletedCall() async {
    if (_openingCallResult || _callSession.activeCall == null) return;
    if (ModalRoute.of(context)?.isCurrent != true) return;
    final resolution = await _callSession.resolveAfterDialer();
    if (!mounted || _openingCallResult || _callSession.activeCall == null) {
      return;
    }
    if (resolution == PendingCallResolution.inProgress ||
        resolution == PendingCallResolution.unverifiable) {
      return;
    }
    final completed = await _callSession.claimCompletedCall();
    if (completed && mounted) await _finishCall();
  }

  void _callSessionChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadEmails() async {
    final id = _prospect.id;
    if (id == null || id < 1) return;
    try {
      final emails = await _emailService.emailHistory(id);
      if (mounted) {
        setState(() {
          _emails = emails;
          _emailError = null;
        });
      }
    } on ProspectsException catch (error) {
      if (mounted) {
        setState(() => _emailError = error.message);
      }
    }
  }

  Future<void> _openEmailOptions() async {
    final prospect = _prospect;
    if (prospect.id == null || prospect.id! < 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El prospecto aún se está sincronizando. Intenta cuando recuperes la conexión.',
          ),
        ),
      );
      return;
    }
    final template = await showAppBottomSheet<ProspectEmailTemplate>(
      context: context,
      showDragHandle: true,
      builder: (_) => ProspectEmailOptionsSheet(email: prospect.email),
    );
    if (template == null || !mounted) return;
    final confirmed = await showAppConfirmationSheet(
      context: context,
      title: 'Confirmar envío',
      message:
          '¿Deseas enviar ${template.label.toLowerCase()} a ${prospect.email}?',
      secondaryLabel: 'Cancelar',
      primaryLabel: 'Enviar',
    );
    if (confirmed == true && mounted) await _sendEmail(template);
  }

  Future<void> _openWhatsApp() async {
    if (!PhoneNumber.isDialable(_prospect.phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El prospecto no tiene un teléfono válido para WhatsApp.',
          ),
        ),
      );
      return;
    }
    final opened = await const ContactLauncher().openWhatsApp(
      _prospect,
      activity: _pendingReminderActivity,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'WhatsApp abierto. Registra el resultado en el formulario de seguimiento.'
              : 'No se pudo abrir WhatsApp.',
        ),
      ),
    );
  }

  Future<void> _openContactEmail() async {
    if (!ContactMedium.correo.isAvailable(_prospect)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El prospecto no tiene un correo válido registrado.'),
        ),
      );
      return;
    }
    final opened = await const ContactLauncher().openEmail(
      _prospect,
      activity: _pendingReminderActivity,
    );
    if (!mounted || opened) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('No se pudo abrir la aplicación de correo.'),
      ),
    );
  }

  Future<void> _openFacebook() async {
    final opened = await const ContactLauncher().openFacebook();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          opened
              ? 'Facebook abierto. Busca el perfil del prospecto y registra el resultado en el seguimiento.'
              : 'No se pudo abrir Facebook.',
        ),
      ),
    );
  }

  Future<void> _runMediumAction(ContactMedium medium) => switch (medium) {
    ContactMedium.llamada => _startCall(),
    ContactMedium.whatsapp => _openWhatsApp(),
    ContactMedium.correo => _openContactEmail(),
    ContactMedium.facebook => _openFacebook(),
  };

  Future<void> _sendEmail(ProspectEmailTemplate template) async {
    if (_sendingEmail || _prospect.id == null) return;
    setState(() => _sendingEmail = true);
    try {
      final sent = await _emailService.sendEmail(
        _prospect.id!,
        template,
        operationKey: PendingOperationsStore.newOperationKey(),
      );
      if (!mounted) return;
      setState(() {
        _emails = [sent, ..._emails];
        _emailError = null;
      });
      await showAppMessageSheet(
        context: context,
        title: 'Correo enviado',
        message: '${template.label} enviado a ${_prospect.email}.',
        actionLabel: 'Aceptar',
      );
    } on ProspectsException catch (error) {
      if (!mounted) return;
      await showAppMessageSheet(
        context: context,
        title: 'No se pudo enviar el correo',
        message: error.message,
        actionLabel: 'Cerrar',
      );
    } finally {
      if (mounted) setState(() => _sendingEmail = false);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _callSession.removeListener(_callSessionChanged);
    _emailService.dispose();
    if (_ownsProspectsRepository) _prospectsRepository.dispose();
    if (_ownsAgendaRepository) _agendaRepository.dispose();
    if (_ownsScriptsRepository) _scriptsRepository.dispose();
    super.dispose();
  }

  Future<void> _convertToClient() async {
    if (_convertingClient) return;
    final confirmed = await showAppBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (_) => ConvertProspectSheet(prospect: _prospect),
    );
    if (_prospect.isClient || confirmed != true || !mounted) return;
    setState(() => _convertingClient = true);
    try {
      final result = await _prospectsRepository.convertToClient(_prospect);
      if (!mounted) return;
      setState(() => _prospect = result.prospect ?? _prospect);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isPending
                ? 'Conversión guardada. Pendiente de sincronizar.'
                : 'Prospecto convertido en cliente.',
          ),
        ),
      );
    } on ProspectsException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _convertingClient = false);
    }
  }

  Future<void> _requestDeletion() async {
    if (_requestingDeletion ||
        _prospect.status.toLowerCase() == 'por eliminar') {
      return;
    }
    final reason = await showAppBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => const ProspectDeletionRequestSheet(),
    );
    if (reason == null || !mounted) return;
    setState(() => _requestingDeletion = true);
    try {
      final result = await _prospectsRepository.requestDeletion(
        _prospect,
        reason,
      );
      if (!mounted) return;
      setState(() => _prospect = result.prospect ?? _prospect);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isPending
                ? 'Solicitud guardada. Pendiente de sincronizar.'
                : 'Solicitud de eliminación enviada.',
          ),
        ),
      );
    } on ProspectsException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) setState(() => _requestingDeletion = false);
    }
  }

  Future<String?> _openDialer() async {
    try {
      await _phoneCallService.call(_prospect.phone);
      return null;
    } on PhoneCallException catch (error) {
      return error.message;
    } on Object {
      return 'No se pudo abrir el marcador del teléfono.';
    }
  }

  Future<void> _startCall() async {
    if (_calling) return;
    if (_callSession.activeCall != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Termina la llamada en curso antes de marcar otro número.',
          ),
        ),
      );
      return;
    }
    if (!PhoneNumber.isDialable(_prospect.phone)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El prospecto no tiene un teléfono válido para llamar.',
          ),
        ),
      );
      return;
    }
    final confirmed = await showAppConfirmationSheet(
      context: context,
      title: 'Antes de marcar',
      message: 'Recuerda informar al prospecto que la llamada será grabada y preguntarle si acepta.',
      secondaryLabel: 'CANCELAR',
      primaryLabel: 'MARCAR',
    );
    if (confirmed != true || !mounted) return;
    final startedAt = businessNow();
    setState(() => _calling = true);
    final errorMessage = await _openDialer();
    if (!mounted) {
      _openingCallResult = false;
      return;
    }
    setState(() => _calling = false);
    if (errorMessage != null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(errorMessage)));
      return;
    }
    await _callSession.start(
      prospect: _prospect,
      origin: 'detalle',
      sourceActivityId: _pendingReminderActivity?.id,
      startedAt: startedAt,
    );
    if (NotificationService.shouldRemindFollowUp(_pendingReminderActivity)) {
      unawaited(
        (widget.showCallReminder ??
            NotificationService.instance.showCallReminder)(_prospect),
      );
    }
  }

  Future<void> _finishCall() async {
    if (_openingCallResult) return;
    final active = _callSession.activeCall;
    if (active == null) return;
    _openingCallResult = true;
    if (await _callSession.isCallInProgress()) {
      _openingCallResult = false;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Termina la llamada antes de registrar el resultado.'),
        ),
      );
      return;
    }
    final logged = await _callSession.latestLog();
    if (!mounted) {
      _openingCallResult = false;
      return;
    }
    final closure = await showAppBottomSheet<ProspectCallClosure>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ProspectCallResultSheet(
        name: active.prospect.name,
        duration: logged == null
            ? _callSession.callDuration
            : Duration(seconds: logged.durationSeconds),
        durationEstimated: logged == null,
        phone: active.prospect.phone,
        startedAt: active.windowStart,
        endedAt: active.realEndedAt ?? DateTime.now(),
      ),
    );
    if (closure == null || !mounted) {
      _openingCallResult = false;
      return;
    }
    final result = await _callSession.finish(
      outcome: closure.outcome,
      consent: closure.consent,
      audio: closure.audio,
    );
    if (!mounted) {
      _openingCallResult = false;
      return;
    }
    if (result.success) {
      setState(() {
        if (result.prospect != null) _prospect = result.prospect!;
        _telephoneCallCompleted = true;
        _telephoneCallSuccessful = closure.outcome.successful;
        _callResultRevision++;
        _callRegistered = true;
        _lastCallId = result.callId;
        _selected.add(ProspectSection.followUp.label);
      });
    }
    _openingCallResult = false;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(result.message)));
  }

  Widget _section(ProspectSection section, Widget child, {String? title}) {
    final palette = AppPalette.of(context);
    final revision = _panelRevisions[section.label] ?? 0;
    return Visibility(
      visible: _selected.contains(section.label),
      maintainState: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ProspectDetailPanel(
          key: ValueKey(section.label),
          title: title ?? section.title,
          color: section.fill(palette),
          foreground: palette.headerForeground,
          initiallyExpanded:
              section == ProspectSection.followUp || revision > 0,
          expansionRevision: revision,
          child: child,
        ),
      ),
    );
  }

  void _toggleSection(String name) => setState(() {
    if (_selected.remove(name)) return;
    _selected.add(name);
    _panelRevisions[name] = (_panelRevisions[name] ?? 0) + 1;
  });

  Future<void> _editOpenedActivity(
    AgendaActivity activity,
    BuildContext detailContext,
  ) async {
    if (activity.id == null ||
        (activity.status != AgendaStatus.pending &&
            activity.status != AgendaStatus.overdue)) {
      ScaffoldMessenger.of(detailContext).showSnackBar(
        const SnackBar(
          content: Text(
            'Solo se pueden editar actividades pendientes o atrasadas.',
          ),
        ),
      );
      return;
    }
    final scheduled = await showAppBottomSheet<DateTime>(
      context: detailContext,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(detailContext).colorScheme.surface,
      builder: (_) => NewAgendaActivityDialog(
        initialDate: activity.date,
        activity: activity,
        agendaRepository: _agendaRepository,
        onActivityUpdated: (updated) {
          if (!mounted) return;
          setState(() {
            if ((_sourceActivity?.id == updated.id ||
                    (_sourceActivity == null && updated.isFollowUp)) &&
                updated.prospectId == _prospect.id) {
              _sourceActivity = updated;
              _prospect = _prospect.copyWith(nextContact: updated.date);
            }
            if (_pendingReminderActivity?.id == updated.id) {
              _pendingReminderActivity = updated;
            }
            if (_pendingFollowUpActivity?.id == updated.id) {
              _pendingFollowUpActivity = updated;
            }
          });
        },
      ),
    );
    if (scheduled == null || !mounted || !detailContext.mounted) return;
    Navigator.pop(detailContext);
    setState(() => _activityContextRevision++);
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Actividad actualizada.')));
  }

  Future<void> _cancelOpenedActivity(
    AgendaActivity activity,
    BuildContext detailContext,
  ) async {
    final confirmed = await showAppConfirmationSheet(
      context: context,
      title: 'Cancelar actividad',
      message: '¿Seguro que deseas cancelar esta actividad? Esta acción no se puede deshacer.',
      secondaryLabel: 'VOLVER',
      primaryLabel: 'SÍ, CANCELAR',
      primaryKey: const ValueKey('confirm-cancel-opened-activity'),
    );
    if (confirmed != true || !detailContext.mounted) return;
    try {
      final result = await _agendaRepository.cancel(activity);
      if (!mounted || !detailContext.mounted) return;
      Navigator.pop(detailContext);
      setState(() {
        if (_sourceActivity?.id == activity.id) {
          _sourceActivity = null;
          _primaryMediumFromActivity = false;
          _primaryMedium = null;
          _mediumResolved = false;
        }
        if (_pendingReminderActivity?.id == activity.id) {
          _pendingReminderActivity = null;
        }
        _activityContextRevision++;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            result.isPending
                ? 'Actividad cancelada. Pendiente de sincronizar.'
                : 'Actividad cancelada.',
          ),
        ),
      );
    } on AgendaException catch (error) {
      if (detailContext.mounted) {
        ScaffoldMessenger.of(detailContext)
            .showSnackBar(SnackBar(content: Text(error.message)));
      }
    }
  }

  void _openActivity(AgendaActivity activity) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (detailContext) => AnnotatedRegion<SystemUiOverlayStyle>(
          value: const SystemUiOverlayStyle(
            statusBarColor: AppColors.primaryColor,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Theme.of(detailContext).colorScheme.surface,
            body: ColoredBox(
              color: AppColors.primaryColor,
              child: SafeArea(
                bottom: false,
                child: AgendaActivityDetail(
                  activity: activity,
                  onClose: () => Navigator.pop(detailContext),
                  onMessage: () => _closeActivityAndRun(
                    detailContext,
                    ContactMedium.parse(activity.medium) ??
                        ContactMedium.llamada,
                  ),
                  onCall: () => _closeActivityAndRun(
                    detailContext,
                    ContactMedium.llamada,
                  ),
                  onContact: (medium) =>
                      _closeActivityAndRun(detailContext, medium),
                  onOpenProspect: () => Navigator.pop(detailContext),
                  onEdit: () => _editOpenedActivity(activity, detailContext),
                  onComplete: () {},
                  onReschedule: () =>
                      _cancelOpenedActivity(activity, detailContext),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _closeActivityAndRun(BuildContext detailContext, ContactMedium medium) {
    Navigator.pop(detailContext);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) unawaited(_runMediumAction(medium));
    });
  }

  bool get _requiresFollowUp =>
      _telephoneCallCompleted && _callRegistered && !_viewingCompletedFollowUp;

  Future<void> _handlePendingCallExit(bool didPop, Object? _) async {
    if (didPop) return;
    if (_requiresFollowUp) {
      await showAppMessageSheet(
        context: context,
        title: 'Seguimiento obligatorio',
        message: 'Después de una llamada debes completar y guardar el formulario de seguimiento antes de salir.',
        actionLabel: 'LLENAR SEGUIMIENTO',
      );
      if (mounted) {
        setState(() => _selected.add(ProspectSection.followUp.label));
      }
      return;
    }
    if (!_hasDirtyForms) return;
    final leave = await showAppBottomSheet<bool>(
      context: context,
      useSafeArea: true,
      showDragHandle: true,
      builder: (sheetContext) => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 18),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Cambios pendientes',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'SulphurPoint',
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tienes cambios sin guardar en: $_dirtyFormLabels.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 6),
              const Text(
                '¿Deseas salir y descartarlos?',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: AppPressBounce(
                      child: TextButton(
                        onPressed: () => Navigator.pop(sheetContext, false),
                        child: const Text('SEGUIR EDITANDO'),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: AppPressBounce(
                      child: FilledButton(
                        key: const ValueKey('discard-pending-form-changes'),
                        onPressed: () => Navigator.pop(sheetContext, true),
                        child: const Text(
                          'SALIR SIN GUARDAR',
                          style: TextStyle(fontSize: 18),
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
    );
    if (leave == true && mounted) {
      setState(() => _allowDirtyPop = true);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = _prospect;
    final palette = AppPalette.of(context);
    final activeCall = _callSession.activeCall;
    final callVerified = activeCall?.verified == true;
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme
            .apply(fontFamily: 'SulphurPoint'),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            textStyle: const TextStyle(fontFamily: 'BebasNeue', fontSize: 18),
          ),
        ),
      ),
      child: PopScope(
        canPop: _allowDirtyPop || (!_requiresFollowUp && !_hasDirtyForms),
        onPopInvokedWithResult: _handlePendingCallExit,
        child: AnnotatedRegion<SystemUiOverlayStyle>(
          value: SystemUiOverlayStyle(
            statusBarColor: palette.brandFill,
            statusBarIconBrightness: Brightness.light,
            statusBarBrightness: Brightness.dark,
          ),
          child: Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            bottomNavigationBar: _viewingCompletedFollowUp
                ? null
                : SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(30, 10, 30, 16),
                      child: Row(
                        children: [
                          _actionButton(
                            'Correos prediseñados',
                            Iconsax.sms_copy,
                            _sendingEmail ? () {} : _openEmailOptions,
                          ),
                          const SizedBox(width: 7),
                          _actionButton(
                            _prospect.isClient
                                ? 'Este prospecto ya es cliente'
                                : 'Convertir en cliente',
                            Iconsax.profile_tick_copy,
                            _convertingClient ? null : _convertToClient,
                            busy: _convertingClient,
                          ),
                          const SizedBox(width: 7),
                          _primaryAction(palette),
                          const SizedBox(width: 7),
                          _actionButton(
                            _prospect.status.toLowerCase() == 'por eliminar'
                                ? 'Eliminación solicitada'
                                : 'Solicitar eliminación',
                            Iconsax.profile_delete_copy,
                            _requestingDeletion ||
                                    _prospect.status.toLowerCase() ==
                                        'por eliminar'
                                ? null
                                : _requestDeletion,
                            busy: _requestingDeletion,
                          ),
                        ],
                      ),
                    ),
                  ),
            body: ColoredBox(
              color: palette.brandFill,
              child: SafeArea(
                child: ColoredBox(
                  color: Theme.of(context).colorScheme.surface,
                  child: Column(
                    children: [
                      if (callVerified)
                        CallRegistrationBar(
                          name: activeCall!.prospect.name,
                          onRegister: _finishCall,
                          onDiscard: () => _callSession.cancel(),
                        ),
                      ProspectDetailHeader(
                        prospect: p,
                        selected: _selected,
                        onToggle: _toggleSection,
                        onScheduleFollowUp:
                            _activityContextResolved &&
                                _pendingFollowUpActivity == null &&
                                p.id != null
                            ? _scheduleFollowUp
                            : null,
                      ),
                      Expanded(
                        child: RefreshIndicator(
                          notificationPredicate: (notification) =>
                              p.id != null &&
                              _commentsKey.currentState != null &&
                              notification.depth == 0,
                          onRefresh: () async {
                            await _loadScripts(force: true);
                            await _commentsKey.currentState?.refresh();
                            await _loadEmails();
                            final id = _prospect.id;
                            if (id != null) {
                              final cached = await _prospectsRepository
                                  .cachedById(id);
                              if (cached != null && mounted) {
                                setState(() => _prospect = cached);
                              }
                            }
                          },
                          child: SingleChildScrollView(
                            physics: const AlwaysScrollableScrollPhysics(
                              parent: BouncingScrollPhysics(),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(14),
                              child: Column(
                                children: [
                                  _section(
                                    ProspectSection.followUp,
                                    ProspectFollowUpForm(
                                      key: ValueKey(
                                        'follow-up-${p.id}-${_sourceActivity?.id}-$_activityContextRevision',
                                      ),
                                      prospect: p,
                                      telephoneCallCompleted:
                                          _telephoneCallCompleted,
                                      callInProgress: callVerified,
                                      callResultRevision: _callResultRevision,
                                      llamadaId: _lastCallId,
                                      initialContactSuccess:
                                          _telephoneCallSuccessful,
                                      sourceActivity: _sourceActivity,
                                      initialMedium:
                                          widget.initialContactMedium,
                                      loadActivities: widget.loadActivities,
                                      onOpenActivity: _openActivity,
                                      onMediumChanged: _resolvePrimaryMedium,
                                      onPendingActivityChanged:
                                          _pendingActivityChanged,
                                      onDirtyChanged: (dirty) => _setFormDirty(
                                        ProspectSection.followUp,
                                        dirty,
                                      ),
                                      onSaved: (entry) {
                                        unawaited(
                                          NotificationService.instance
                                              .cancelCallReminder(),
                                        );
                                        setState(() {
                                          _history.insert(0, entry);
                                          _telephoneCallCompleted = false;
                                          _callRegistered = true;
                                          _followUpSaved =
                                              _sourceActivity != null;
                                          _pendingReminderActivity = null;
                                        });
                                        _commentsKey.currentState?.refresh();
                                      },
                                      onProspectUpdated: (updated) =>
                                          setState(() => _prospect = updated),
                                      readOnly: _formsReadOnly,
                                    ),
                                    title: _formsReadOnly
                                        ? 'Seguimiento registrado'
                                        : null,
                                  ),
                                  _section(
                                    ProspectSection.discovery,
                                    ProspectDiscoveryForm(
                                      prospectId: p.id,
                                      prospect: p,
                                      readOnly: _formsReadOnly,
                                      onDirtyChanged: (dirty) => _setFormDirty(
                                        ProspectSection.discovery,
                                        dirty,
                                      ),
                                      onSaved: (summary) => setState(
                                        () => _history.insert(0, summary),
                                      ),
                                      onProspectUpdated: _applyProspectUpdate,
                                    ),
                                  ),
                                  _section(
                                    ProspectSection.scripts,
                                    ProspectScriptsPanel(
                                      guiones: _guiones,
                                      loading: _scriptsLoading,
                                      error: _scriptsError,
                                      offline: _scriptsOffline,
                                      onRetry: () => _loadScripts(force: true),
                                      prospectName: p.name,
                                      asesorName: AuthService.instance.userName,
                                      desarrolloName: p.interestDevelopment,
                                      emptyMessage:
                                          p.interestDevelopmentId == null
                                          ? 'Este prospecto no tiene un desarrollo asignado.'
                                          : null,
                                    ),
                                  ),
                                  _section(
                                    ProspectSection.data,
                                    ProspectDataForm(
                                      prospect: p,
                                      repository: _prospectsRepository,
                                      onProspectUpdated: _applyProspectUpdate,
                                      readOnly: _formsReadOnly,
                                      onDirtyChanged: (dirty) => _setFormDirty(
                                        ProspectSection.data,
                                        dirty,
                                      ),
                                      onSaved: (summary) => setState(
                                        () => _history.insert(0, summary),
                                      ),
                                    ),
                                  ),
                                  _section(
                                    ProspectSection.history,
                                    p.id != null
                                        ? Column(
                                            children: [
                                              ProspectCommentsPanel(
                                                key: _commentsKey,
                                                prospectId: p.id!,
                                              ),
                                              const SizedBox(height: 10),
                                              ProspectEmailHistoryPanel(
                                                emails: _emails,
                                                error: _emailError,
                                                onRetry: _loadEmails,
                                              ),
                                            ],
                                          )
                                        : ProspectHistory(
                                            comments:
                                                demoProspectHistoryComments,
                                            discoverySummary:
                                                demoProspectDiscoverySummary,
                                            emails: demoProspectEmailHistory,
                                            callHours: demoProspectCallHours,
                                            sessionEntries: _history,
                                          ),
                                  ),
                                ],
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
          ),
        ),
      ),
    );
  }
}
