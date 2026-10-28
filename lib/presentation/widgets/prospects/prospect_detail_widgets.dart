import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_avatar_badge.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';

/// Secciones plegables del detalle del prospecto: etiqueta del chip, título
/// del panel y colores con los que se pintan (se adaptan al modo claro/oscuro).
enum ProspectSection {
  followUp('Seguimiento', 'Registrar seguimiento'),
  discovery('Discovery', 'Registrar discovery'),
  scripts('Guiones', 'Guiones de llamadas'),
  data('Prospecto', 'Datos del prospecto'),
  history('Historial', 'Historial');

  const ProspectSection(this.label, this.title);

  final String label;
  final String title;

  static ProspectSection? byLabel(String label) {
    for (final section in values) {
      if (section.label == label) return section;
    }
    return null;
  }

  Color fill(AppPalette palette) => switch (this) {
    ProspectSection.followUp => palette.insertFollowUpFill,
    ProspectSection.discovery => palette.insertDiscoveryFill,
    ProspectSection.scripts => palette.insertScriptsFill,
    ProspectSection.data => palette.insertDataFill,
    ProspectSection.history => palette.insertHistoryFill,
  };

  Color ink(AppPalette palette) => switch (this) {
    ProspectSection.followUp => palette.insertFollowUpInk,
    ProspectSection.discovery => palette.insertDiscoveryInk,
    ProspectSection.scripts => palette.insertScriptsInk,
    ProspectSection.data => palette.insertDataInk,
    ProspectSection.history => palette.insertHistoryInk,
  };
}

class ProspectDetailHeader extends StatelessWidget {
  final ProspectRecord prospect;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  const ProspectDetailHeader({
    super.key,
    required this.prospect,
    required this.selected,
    required this.onToggle,
  });

  Widget _date(BuildContext context, DateTime? date) {
    const days = [
      'lunes',
      'martes',
      'miércoles',
      'jueves',
      'viernes',
      'sábado',
      'domingo',
    ];
    const months = [
      'Ene',
      'Feb',
      'Mar',
      'Abr',
      'May',
      'Jun',
      'Jul',
      'Ago',
      'Sep',
      'Oct',
      'Nov',
      'Dic',
    ];
    return _badge(
      context,
      date == null
          ? const Text('Sin fecha')
          : Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      days[date.weekday - 1],
                      style: const TextStyle(fontSize: 13),
                    ),
                    Text(
                      '${date.day}'.padLeft(2, '0'),
                      style: const TextStyle(fontSize: 15, height: 1),
                    ),
                  ],
                ),
                Text(
                  '${months[date.month - 1]} ${date.year}',
                  style: const TextStyle(fontSize: 13, height: 1.2),
                ),
              ],
            ),
    );
  }

  Widget _badge(BuildContext context, Widget child) {
    final palette = AppPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: palette.headerBadgeFill,
        borderRadius: BorderRadius.circular(6),
      ),
      child: DefaultTextStyle(
        style: TextStyle(
          fontFamily: 'SulphurPoint',
          color: palette.headerBadgeForeground,
        ),
        child: child,
      ),
    );
  }

  Widget _group(BuildContext context, String label, Widget child) => Column(
    children: [
      child,
      const SizedBox(height: 6),
      Text(
        label,
        style: TextStyle(
          fontSize: 13,
          color: AppPalette.of(context).headerForeground,
        ),
      ),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final next = prospect.nextContact;
    return Container(
      decoration: BoxDecoration(
        color: palette.brandFill,
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  tooltip: 'Volver',
                  color: palette.headerForeground,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints.tightFor(
                    width: 40,
                    height: 40,
                  ),
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_ios_new, size: 24),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        prospect.name.toUpperCase(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          color: palette.headerBadgeForeground,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        prospect.status.toUpperCase(),
                        style: TextStyle(
                          fontFamily: 'BebasNeue',
                          color: palette.headerForeground,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ProspectAvatarBadge(prospect: prospect),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              spacing: 12,
              runSpacing: 16,
              children: [
                _group(
                  context,
                  'Próximo contacto',
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _date(context, next),
                      if (next != null) ...[
                        _badge(
                          context,
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${next.hour % 12 == 0 ? 12 : next.hour % 12}:${next.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(
                                  fontSize: 15,
                                  height: 1.1,
                                ),
                              ),
                              Text(
                                next.hour < 12 ? 'am' : 'pm',
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                _group(
                  context,
                  'Fecha de asignación',
                  _date(context, prospect.assignedAt),
                ),
                _group(
                  context,
                  'Venta',
                  _badge(
                    context,
                    Text(
                      prospect.status == 'Venta realizada' ? 'SÍ' : 'NO',
                      style: const TextStyle(fontSize: 24),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 18),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: ProspectSection.values
                    .map(
                      (section) => Padding(
                        padding: const EdgeInsets.only(right: 6),
                        child: FilterChip(
                          label: Text(section.label),
                          selected: selected.contains(section.label),
                          onSelected: (_) => onToggle(section.label),
                          showCheckmark: false,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          padding: EdgeInsets.zero,
                          labelPadding: EdgeInsets.symmetric(
                            vertical: 5,
                            horizontal: 7,
                          ),
                          backgroundColor: palette.headerChipFill,
                          selectedColor: section.fill(palette),
                          labelStyle: TextStyle(
                            fontFamily: 'SulphurPoint',
                            fontSize: 12,
                            color: selected.contains(section.label)
                                ? section.ink(palette)
                                : palette.headerChipForeground,
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ProspectDetailPanel extends StatefulWidget {
  final String title;
  final Color color;

  /// Tinta del título. Por defecto se resuelve según [nested].
  final Color? foreground;
  final Widget child;
  final bool initiallyExpanded;
  final bool nested;
  const ProspectDetailPanel({
    super.key,
    required this.title,
    required this.color,
    this.foreground,
    required this.child,
    this.initiallyExpanded = false,
    this.nested = false,
  });
  @override
  State<ProspectDetailPanel> createState() => _ProspectDetailPanelState();
}

class _ProspectDetailPanelState extends State<ProspectDetailPanel> {
  late bool _expanded = widget.initiallyExpanded;
  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Material(
      color: widget.color,
      borderRadius: BorderRadius.circular(13),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: widget.nested ? 16 : 18,
                        fontFamily: 'SulphurPoint',
                        color:
                            widget.foreground ??
                            (widget.nested
                                ? palette.headerForeground
                                : palette.cardInk),
                      ),
                    ),
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: palette.panelArrowFill,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Icon(
                      _expanded
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: palette.panelArrowForeground,
                      size: 26,
                    ),
                  ),
                ],
              ),
            ),
          ),
          Visibility(
            visible: _expanded,
            maintainState: true,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
