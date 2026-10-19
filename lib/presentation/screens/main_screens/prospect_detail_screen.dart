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
import 'package:callerapp_frontend/resources/colors/colors.dart';
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
  bool _telephoneCallCompleted = false;
  Widget _actionButton(String label, IconData icon, VoidCallback onPressed) =>
      Expanded(
        child: SizedBox(
          height: 48,
          child: IconButton.filledTonal(
            tooltip: label,
            style: IconButton.styleFrom(
              backgroundColor: const Color(0xFFACEFE2),
              foregroundColor: const Color(0xFF398C80),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onPressed: onPressed,
            icon: Icon(icon, size: 30),
          ),
        ),
      );
  @override
  void dispose() {
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

  Widget _section(String name, String title, Color color, Widget child) =>
      Visibility(
        visible: _selected.contains(name),
        maintainState: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ProspectDetailPanel(
            key: ValueKey('$name-${_panelRevisions[name] ?? 0}'),
            title: title,
            color: color,
            initiallyExpanded:
                name == 'Seguimiento' || (_panelRevisions[name] ?? 0) > 0,
            child: child,
          ),
        ),
      );

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
                  'Datos para mensaje',
                  Iconsax.send_2_copy,
                  () => _contact(),
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
                        backgroundColor: AppColors.primaryColor,
                        foregroundColor: AppColors.homeWarmText,
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
          child: Stack(
            children: [
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                height: 265,
                child: Container(
                  decoration: const BoxDecoration(
                    color: AppColors.primaryColor,
                    borderRadius: BorderRadius.vertical(
                      bottom: Radius.circular(28),
                    ),
                  ),
                ),
              ),
              RefreshIndicator(
                notificationPredicate: (notification) =>
                    p.id != null &&
                    _commentsKey.currentState != null &&
                    notification.depth == 0,
                onRefresh: () =>
                    _commentsKey.currentState?.refresh() ??
                    Future<void>.value(),
                child: SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(
                    parent: BouncingScrollPhysics(),
                  ),
                  child: Column(
                    children: [
                      ProspectDetailHeader(
                        prospect: p,
                        selected: _selected,
                        onToggle: _toggleSection,
                      ),
                      Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          children: [
                            _section(
                              'Seguimiento',
                              'Registrar seguimiento',
                              const Color(0xFF96E3F4),
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
                              'Discovery',
                              'Registrar discovery',
                              const Color(0xFF95FF90),
                              ProspectDiscoveryForm(
                                prospectId: p.id,
                                onSaved: (summary) =>
                                    setState(() => _history.insert(0, summary)),
                              ),
                            ),
                            _section(
                              'Guiones',
                              'Guiones de llamadas',
                              const Color(0xFFFFF18A),
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
                              'Prospecto',
                              'Datos del prospecto',
                              const Color(0xFFFF929C),
                              ProspectDataForm(
                                prospect: p,
                                onSaved: (summary) =>
                                    setState(() => _history.insert(0, summary)),
                              ),
                            ),
                            _section(
                              'Historial',
                              'Historial',
                              const Color(0xFFCE82F3),
                              p.id != null
                                  ? ProspectCommentsPanel(
                                      key: _commentsKey,
                                      prospectId: p.id!,
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
                    ],
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
