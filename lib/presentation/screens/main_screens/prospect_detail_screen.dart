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
import 'package:callerapp_frontend/presentation/models/prospect_email_models.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/data/local/pending_operations_store.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class ProspectDetailArguments {
  const ProspectDetailArguments({required this.prospect, this.sourceActivity});
  final ProspectRecord prospect;
  final AgendaActivity? sourceActivity;
}

class ProspectDetailScreen extends StatefulWidget {
  final ProspectRecord prospect;
  final AgendaActivity? sourceActivity;
  final Future<List<AgendaActivity>> Function()? loadActivities;
  const ProspectDetailScreen({
    super.key,
    required this.prospect,
    this.sourceActivity,
    this.loadActivities,
  });
  @override
  State<ProspectDetailScreen> createState() => _ProspectDetailScreenState();
}

class _ProspectDetailScreenState extends State<ProspectDetailScreen> {
  final _commentsKey = GlobalKey<ProspectCommentsPanelState>();
  final _selected = {'Seguimiento', 'Discovery'};
  final _panelRevisions = <String, int>{};
  final _history = <String>[];
  final _emailService = ProspectsService();
  List<ProspectEmailHistoryEntry> _emails = const [];
  String? _emailError;
  bool _sendingEmail = false;
  bool _telephoneCallCompleted = false;
  Widget _actionButton(String label, IconData icon, VoidCallback onPressed) {
    final palette = AppPalette.of(context);
    return Expanded(
      child: SizedBox(
        height: 48,
        child: IconButton.filledTonal(
          tooltip: label,
          style: IconButton.styleFrom(
            backgroundColor: palette.secondaryActionFill,
            foregroundColor: palette.secondaryActionForeground,
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
    _loadEmails();
  }

  Future<void> _loadEmails() async {
    final id = widget.prospect.id;
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
    final prospect = widget.prospect;
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
    if (_sendingEmail || widget.prospect.id == null) return;
    setState(() => _sendingEmail = true);
    try {
      final sent = await _emailService.sendEmail(
        widget.prospect.id!,
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
          content: Text(
            '${template.label} enviado a ${widget.prospect.email}.',
          ),
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
    _emailService.dispose();
    super.dispose();
  }

  Future<void> _contact({bool phoneCall = false}) async {
    final completed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(widget.prospect.name),
              SelectableText(widget.prospect.phone),
              SelectableText(widget.prospect.email),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(
                    ClipboardData(text: widget.prospect.phone),
                  );
                  if (context.mounted) Navigator.pop(context);
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar teléfono'),
              ),
              if (phoneCall)
                FilledButton.icon(
                  key: const ValueKey('finish-prospect-call'),
                  onPressed: () => Navigator.pop(context, true),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('TERMINÉ LA LLAMADA'),
                ),
            ],
          ),
        ),
      ),
    );
    if (completed == true && mounted) {
      setState(() => _telephoneCallCompleted = true);
    }
  }

  Widget _section(ProspectSection section, Widget child) {
    final palette = AppPalette.of(context);
    final revision = _panelRevisions[section.label] ?? 0;
    return Visibility(
      visible: _selected.contains(section.label),
      maintainState: true,
      child: Padding(
        padding: const EdgeInsets.only(bottom: 16),
        child: ProspectDetailPanel(
          key: ValueKey('${section.label}-$revision'),
          title: section.title,
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

  @override
  Widget build(BuildContext context) {
    final p = widget.prospect;
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
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        bottomNavigationBar: SafeArea(
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
                  'Datos del prospecto',
                  Iconsax.profile_tick_copy,
                  () => _contact(),
                ),
                const SizedBox(width: 7),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 58,
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        backgroundColor: palette.brandFill,
                        foregroundColor: palette.onBrand,
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => _contact(phoneCall: true),
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Iconsax.call_calling, size: 25),
                          SizedBox(height: 2),
                          Text(
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
                              sourceActivity: widget.sourceActivity,
                              loadActivities: widget.loadActivities,
                              onOpenActivity: _openActivity,
                              onSaved: (entry) {
                                setState(() {
                                  _history.insert(0, entry);
                                  _telephoneCallCompleted = false;
                                });
                                _commentsKey.currentState?.refresh();
                              },
                            ),
                          ),
                          _section(
                            ProspectSection.discovery,
                            ProspectDiscoveryForm(
                              prospectId: p.id,
                              prospect: p,
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
    );
  }
}
