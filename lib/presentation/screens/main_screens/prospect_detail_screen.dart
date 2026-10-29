import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_activity_detail.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_follow_up_form.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_discovery_form.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_data_form.dart';
import 'package:callerapp_frontend/presentation/models/call_script_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_history_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_call_scripts.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_history.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_comments_panel.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_email_options_sheet.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_email_history_panel.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/call_in_progress_bar.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_call_result_sheet.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_contact_sheet.dart';
import 'package:callerapp_frontend/presentation/models/prospect_email_models.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/services/phone_call_service.dart';
import 'package:callerapp_frontend/services/phone_number.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/presentation/models/call_models.dart';
import 'package:callerapp_frontend/services/call_session_controller.dart';
import 'package:callerapp_frontend/data/local/pending_operations_store.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class ProspectDetailArguments {
  const ProspectDetailArguments({
    required this.prospect,
    this.sourceActivity,
    this.callStarted = false,
    this.callSuccessful = false,
  });
  final ProspectRecord prospect;
  final AgendaActivity? sourceActivity;
  final bool callStarted;
  final bool callSuccessful;
}

class ProspectDetailScreen extends StatefulWidget {
  final ProspectRecord prospect;
  final AgendaActivity? sourceActivity;
  final Future<List<AgendaActivity>> Function()? loadActivities;
  final PhoneCallService? phoneCallService;
  final bool callStarted;
  final bool callSuccessful;
  const ProspectDetailScreen({
    super.key,
    required this.prospect,
    this.sourceActivity,
    this.loadActivities,
    this.phoneCallService,
    this.callStarted = false,
    this.callSuccessful = false,
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
  List<ProspectEmailHistoryEntry> _emails = const [];
  String? _emailError;
  bool _sendingEmail = false;
  bool _telephoneCallCompleted = false;
  bool _telephoneCallSuccessful = false;
  bool _callRegistered = false;
  bool _calling = false;
  final _callSession = CallSessionController.instance;
  int? _lastCallId;
  bool _openingCallResult = false;
  bool get _viewingCompletedFollowUp =>
      widget.sourceActivity?.isFollowUp == true &&
      widget.sourceActivity?.status == AgendaStatus.completed;
  Widget _actionButton(String label, IconData icon, VoidCallback onPressed) {
    final palette = AppPalette.of(context);
    return Expanded(
      child: SizedBox(
        height: 48,
        child: IconButton.filledTonal(
          tooltip: label,
          style: IconButton.styleFrom(
            backgroundColor: palette.secondaryActionForeground,
            foregroundColor: palette.secondaryActionFill,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          onPressed: onPressed,
          icon: Icon(icon, size: 30),
        ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _phoneCallService = widget.phoneCallService ?? PhoneCallService();
    WidgetsBinding.instance.addObserver(this);
    _prospect = widget.prospect;
    _telephoneCallCompleted = widget.callStarted;
    _telephoneCallSuccessful = widget.callSuccessful;
    _callRegistered = widget.callStarted;
    _callSession.addListener(_callSessionChanged);
    if (_viewingCompletedFollowUp) {
      _selected.addAll(ProspectSection.values.map((section) => section.label));
    }
    _loadEmails();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _detectCompletedCall();
    }
  }

  Future<void> _detectCompletedCall() async {
    if (_openingCallResult || _callSession.activeCall == null) return;
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
    final template = await showModalBottomSheet<ProspectEmailTemplate>(
      context: context,
      showDragHandle: true,
      builder: (_) => ProspectEmailOptionsSheet(email: prospect.email),
    );
    if (template == null || !mounted) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Confirmar envío'),
        content: Text(
          '¿Deseas enviar ${template.label.toLowerCase()} a ${prospect.email}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('Enviar'),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) await _sendEmail(template);
  }

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
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Correo enviado'),
          content: Text('${template.label} enviado a ${_prospect.email}.'),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Aceptar'),
            ),
          ],
        ),
      );
    } on ProspectsException catch (error) {
      if (!mounted) return;
      await showDialog<void>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('No se pudo enviar el correo'),
          content: Text(error.message),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cerrar'),
            ),
          ],
        ),
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
    super.dispose();
  }

  Future<void> _copyPhone(BuildContext sheetContext) async {
    await Clipboard.setData(ClipboardData(text: _prospect.phone));
    if (sheetContext.mounted) Navigator.pop(sheetContext);
  }

  Future<void> _contact() => showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    builder: (sheetContext) => ProspectContactSheet(
      name: _prospect.name,
      phone: _prospect.phone,
      email: _prospect.email,
      onCopyPhone: () => _copyPhone(sheetContext),
    ),
  );

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
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Antes de marcar'),
        content: const Text(
          'Recuerda informar al prospecto que la llamada será grabada y preguntarle si acepta. Si aún no lo sabes, puedes marcar y confirmarlo al terminar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CANCELAR'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('MARCAR'),
          ),
        ],
      ),
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
      sourceActivityId: widget.sourceActivity?.id,
      startedAt: startedAt,
    );
  }

  Future<void> _finishCall() async {
    if (_openingCallResult) return;
    final active = _callSession.activeCall;
    if (active == null) return;
    _openingCallResult = true;
    final logged = await _callSession.latestLog();
    if (!mounted) {
      _openingCallResult = false;
      return;
    }
    final closure = await showModalBottomSheet<ProspectCallClosure>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      builder: (_) => ProspectCallResultSheet(
        name: active.prospect.name,
        duration: logged == null
            ? _callSession.elapsed
            : Duration(seconds: logged.durationSeconds),
        durationEstimated: logged == null,
        phone: active.prospect.phone,
        startedAt: active.startedAt,
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
        _callRegistered = true;
        _lastCallId = result.callId;
        _selected.add(ProspectSection.followUp.label);
        _panelRevisions[ProspectSection.followUp.label] =
            (_panelRevisions[ProspectSection.followUp.label] ?? 0) + 1;
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
          key: ValueKey('${section.label}-$revision'),
          title: title ?? section.title,
          color: section.fill(palette),
          foreground: section.ink(palette),
          initiallyExpanded:
              section == ProspectSection.followUp || revision > 0,
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

  void _openActivity(AgendaActivity activity) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (detailContext) => Scaffold(
          body: SafeArea(
            bottom: false,
            child: AgendaActivityDetail(
              activity: activity,
              onClose: () => Navigator.pop(detailContext),
              onMessage: () {},
              onCall: () {},
              onOpenProspect: () => Navigator.pop(detailContext),
              onEdit: () {},
              onComplete: () {},
              onReschedule: () {},
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _handlePendingCallExit(bool didPop, Object? _) async {
    if (didPop || !_telephoneCallCompleted || _callRegistered) return;
    final discard = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Llamada sin registrar'),
        content: const Text(
          'La llamada aún no está registrada en el seguimiento. ¿Deseas salir sin guardarla?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('CONTINUAR EDITANDO'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text('SALIR SIN GUARDAR'),
          ),
        ],
      ),
    );
    if (discard == true && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = _prospect;
    final palette = AppPalette.of(context);
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
        canPop: !_telephoneCallCompleted || _callRegistered,
        onPopInvokedWithResult: _handlePendingCallExit,
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
                          'Enviar correo',
                          Iconsax.send_2_copy,
                          _sendingEmail ? () {} : _openEmailOptions,
                        ),
                        const SizedBox(width: 7),
                        _actionButton(
                          'Datos de contacto',
                          Iconsax.profile_tick_copy,
                          _contact,
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          flex: 2,
                          child: SizedBox(
                            height: 54,
                            child: FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: palette.brandFill,
                                foregroundColor: palette.onBrand,
                                padding: EdgeInsets.zero,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              onPressed: _calling ? null : _startCall,
                              child: Semantics(
                                label: 'Llamar a ${p.name}',
                                button: true,
                                enabled: !_calling,
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    _calling
                                        ? const SizedBox(
                                            width: 20,
                                            height: 20,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          )
                                        : const Icon(
                                            Iconsax.call_calling,
                                            size: 25,
                                          ),
                                    const SizedBox(height: 2),
                                    const Text(
                                      'Llamar',
                                      style: TextStyle(
                                        fontFamily: 'SulphurPoint',
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 7),
                        _actionButton(
                          'Descartar prospecto',
                          Iconsax.profile_delete_copy,
                          () => ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'El descarte estará disponible al conectar el servicio.',
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
          body: SafeArea(
            child: Column(
              children: [
                if (_callSession.activeCall != null)
                  CallInProgressBar(
                    name: _callSession.activeCall!.prospect.name,
                    elapsed: _callSession.elapsed,
                    onFinish: _finishCall,
                  ),
                ProspectDetailHeader(
                  prospect: p,
                  selected: _selected,
                  onToggle: _toggleSection,
                ),
                Expanded(
                  child: RefreshIndicator(
                    notificationPredicate: (notification) =>
                        p.id != null &&
                        _commentsKey.currentState != null &&
                        notification.depth == 0,
                    onRefresh: () async {
                      await _commentsKey.currentState?.refresh();
                      await _loadEmails();
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
                                  'follow-up-$_telephoneCallCompleted',
                                ),
                                prospect: p,
                                telephoneCallCompleted: _telephoneCallCompleted,
                                callInProgress: _callSession.activeCall != null,
                                llamadaId: _lastCallId,
                                initialContactSuccess: _telephoneCallSuccessful,
                                sourceActivity: widget.sourceActivity,
                                loadActivities: widget.loadActivities,
                                onOpenActivity: _openActivity,
                                onSaved: (entry) {
                                  setState(() {
                                    _history.insert(0, entry);
                                    _telephoneCallCompleted = false;
                                    _callRegistered = true;
                                  });
                                  _commentsKey.currentState?.refresh();
                                },
                                onProspectUpdated: (updated) =>
                                    setState(() => _prospect = updated),
                                readOnly: _viewingCompletedFollowUp,
                              ),
                              title: _viewingCompletedFollowUp
                                  ? 'Seguimiento registrado'
                                  : null,
                            ),
                            _section(
                              ProspectSection.discovery,
                              ProspectDiscoveryForm(
                                prospectId: p.id,
                                prospect: p,
                                readOnly: _viewingCompletedFollowUp,
                                onSaved: (summary) =>
                                    setState(() => _history.insert(0, summary)),
                              ),
                            ),
                            _section(
                              ProspectSection.scripts,
                              Column(
                                children: [
                                  ProspectCallScripts(
                                    script: demoAlanCallScript,
                                    prospectName: p.name,
                                  ),
                                  const SizedBox(height: 12),
                                  ProspectFollowUpCallScript(
                                    prospectName: p.name,
                                    onContinue: () => setState(
                                      () => _history.insert(
                                        0,
                                        'Guiones · Continuar al cierre',
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            _section(
                              ProspectSection.data,
                              ProspectDataForm(
                                prospect: p,
                                readOnly: _viewingCompletedFollowUp,
                                onSaved: (summary) =>
                                    setState(() => _history.insert(0, summary)),
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
                                      comments: demoProspectHistoryComments,
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
    );
  }
}
