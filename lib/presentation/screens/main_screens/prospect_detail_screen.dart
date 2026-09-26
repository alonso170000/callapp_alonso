import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_detail_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_follow_up_form.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_discovery_form.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_data_form.dart';
import 'package:callerapp_frontend/presentation/models/call_script_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_history_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_call_scripts.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_history.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class ProspectDetailScreen extends StatefulWidget {
  final ProspectRecord prospect;
  const ProspectDetailScreen({super.key, required this.prospect});
  @override
  State<ProspectDetailScreen> createState() => _ProspectDetailScreenState();
}

class _ProspectDetailScreenState extends State<ProspectDetailScreen> {
  final _selected = {'Seguimiento', 'Discovery'};
  final _history = <String>[];
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
            icon: Icon(icon, size: 23),
          ),
        ),
      );
  @override
  void dispose() {
    super.dispose();
  }

  void _contact() => showModalBottomSheet<void>(
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
          ],
        ),
      ),
    ),
  );

  Widget _section(String name, String title, Color color, Widget child) =>
      Visibility(
        visible: _selected.contains(name),
        maintainState: true,
        child: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: ProspectDetailPanel(title: title, color: color, child: child),
        ),
      );
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
        backgroundColor: AppColors.homeBackground,
        bottomNavigationBar: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(30, 10, 30, 16),
            child: Row(
              children: [
                _actionButton(
                  'Datos para mensaje',
                  Icons.send_outlined,
                  _contact,
                ),
                const SizedBox(width: 7),
                _actionButton(
                  'Datos del prospecto',
                  Icons.contact_page_outlined,
                  _contact,
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
                      onPressed: _contact,
                      child: const Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.phone_in_talk, size: 25),
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
                  Icons.person_remove_outlined,
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
              SingleChildScrollView(
                child: Column(
                  children: [
                    ProspectDetailHeader(
                      prospect: p,
                      selected: _selected,
                      onToggle: (name) => setState(() {
                        _selected.contains(name)
                            ? _selected.remove(name)
                            : _selected.add(name);
                      }),
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
                              prospect: p,
                              onSaved: (entry) =>
                                  setState(() => _history.insert(0, entry)),
                            ),
                          ),
                          _section(
                            'Discovery',
                            'Registrar discovery',
                            const Color(0xFF95FF90),
                            ProspectDiscoveryForm(
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
                                const ProspectCallScripts(
                                  script: demoAlanCallScript,
                                ),
                                const SizedBox(height: 12),
                                ProspectFollowUpCallScript(
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
                            ProspectHistory(
                              comments: demoProspectHistoryComments,
                              discoverySummary: demoProspectDiscoverySummary,
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
            ],
          ),
        ),
      ),
    );
  }
}
