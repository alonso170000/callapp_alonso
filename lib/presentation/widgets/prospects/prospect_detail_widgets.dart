import 'package:callerapp_frontend/presentation/widgets/app_press_bounce.dart';
import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_avatar_badge.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_tag.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/colors/prospect_tag_colors.dart';
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
    ProspectSection.followUp => palette.chipFollowUp,
    ProspectSection.discovery => palette.chipDiscovery,
    ProspectSection.scripts => palette.chipScripts,
    ProspectSection.data => palette.chipData,
    ProspectSection.history => palette.chipHistory,
  };
}

class ProspectDetailHeader extends StatelessWidget {
  final ProspectRecord prospect;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final VoidCallback? onScheduleFollowUp;
  const ProspectDetailHeader({
    super.key,
    required this.prospect,
    required this.selected,
    required this.onToggle,
    this.onScheduleFollowUp,
  });

  Widget _dateBadge(BuildContext context, DateTime? date) {
    const days = ['lun', 'mar', 'mié', 'jue', 'vie', 'sáb', 'dom'];
    const months = [
      'ene',
      'feb',
      'mar',
      'abr',
      'may',
      'jun',
      'jul',
      'ago',
      'sep',
      'oct',
      'nov',
      'dic',
    ];
    if (date == null) return _textBadge(context, 'Sin fecha', fontSize: 15);
    return _badgeSurface(
      context,
      FittedBox(
        fit: BoxFit.scaleDown,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      days[date.weekday - 1],
                      style: const TextStyle(fontSize: 12, height: 1.3),
                    ),
                    Text(
                      months[date.month - 1],
                      style: const TextStyle(fontSize: 12, height: 0.75),
                    ),
                  ],
                ),
                const SizedBox(width: 3),
                Text(
                  date.day.toString().padLeft(2, '0'),
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.w500,
                    height: 0.95,
                  ),
                ),
              ],
            ),
            Text(
              '${date.year}',
              maxLines: 1,
              style: const TextStyle(fontSize: 11, height: 0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _timeBadge(BuildContext context, DateTime date) => _badgeSurface(
    context,
    FittedBox(
      fit: BoxFit.scaleDown,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '${date.hour % 12 == 0 ? 12 : date.hour % 12}:${date.minute.toString().padLeft(2, '0')}',
            maxLines: 1,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.w500,
              height: 1,
            ),
          ),
          Text(
            date.hour < 12 ? 'am' : 'pm',
            maxLines: 1,
            style: const TextStyle(fontSize: 12, height: 0.5),
          ),
        ],
      ),
    ),
  );

  Widget _textBadge(
    BuildContext context,
    String text, {
    required double fontSize,
    double height = 0.95,
  }) {
    final isStaggered = text == 'Sin\nventa' || text == 'Venta\nrealizada';
    final lines = text.split('\n');

    return _badgeSurface(
      context,
      FittedBox(
        fit: BoxFit.scaleDown,
        child: isStaggered && lines.length == 2
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    lines[0],
                    style: TextStyle(
                      fontSize: fontSize,
                      height: height,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      lines[1], //
                      style: TextStyle(
                        fontSize: fontSize,
                        height: 0.7,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              )
            : Text(
                text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: fontSize,
                  height: height,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ),
    );
  }

  Widget _badgeSurface(BuildContext context, Widget child) {
    final palette = AppPalette.of(context);
    return Container(
      height: 56,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: palette.headerBadgeFill,
        borderRadius: BorderRadius.circular(12),
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

  Widget _indicator(
    BuildContext context, {
    required Widget badge,
    String? label,
    Key? key,
  }) => Column(
    key: key,
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      badge,
      const SizedBox(height: 5),
      _indicatorLabel(context, label),
    ],
  );

  Widget _indicatorLabel(BuildContext context, String? label) => SizedBox(
    height: 18,
    child: label == null
        ? const SizedBox.shrink()
        : FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              style: TextStyle(
                fontFamily: 'SulphurPoint',
                fontSize: 13,
                color: AppColors.whiteColor,
              ),
            ),
          ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final next = prospect.nextContact;
    final showNextTime = next != null && (next.hour != 0 || next.minute != 0);
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
                AppPressBounce(
                  child: IconButton(
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
                      Wrap(
                        spacing: 4,
                        children: [
                          ProspectStatusTag(status: prospect.status),
                          if (prospect.isClient)
                            ProspectTag(
                              label: 'CLIENTE',
                              background: ProspectTagColors.client,
                              foreground: ProspectTagColors.clientForeground,
                            ),
                        ],
                      ),
                      SizedBox(height: 2),
                      if (prospect.assignedBy != null)
                        Text(
                          'Asignado por ${prospect.assignedBy?.split(' ').take(2).join(' ')}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: palette.headerForeground,
                            fontFamily: 'SulphurPoint',
                            fontSize: 11,
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                ProspectAvatarBadge(
                  prospect: prospect,
                  borderColor: prospect.isClient
                      ? AppColors.prospectClientAvatarBorder
                      : null,
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: showNextTime ? 2 : 1,
                  child: Semantics(
                    button: true,
                    enabled: onScheduleFollowUp != null,
                    label: next == null
                        ? 'Agendar próximo contacto'
                        : 'Próximo contacto agendado',
                    child: InkWell(
                      key: const ValueKey('schedule-follow-up-indicator'),
                      borderRadius: BorderRadius.circular(12),
                      onTap: onScheduleFollowUp,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: next == null
                                    ? _textBadge(
                                        context,
                                        'Sin agendar',
                                        fontSize: 17,
                                      )
                                    : _dateBadge(context, next),
                              ),
                              if (showNextTime) ...[
                                const SizedBox(width: 8),
                                Expanded(
                                  child: KeyedSubtree(
                                    key: const ValueKey(
                                      'next-contact-time-indicator',
                                    ),
                                    child: _timeBadge(context, next),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 5),
                          _indicatorLabel(context, 'Próximo contacto'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _indicator(
                    context,
                    key: const ValueKey('assignment-date-indicator'),
                    label: 'Asignación',
                    badge: _dateBadge(context, prospect.assignedAt),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _indicator(
                    context,
                    key: const ValueKey('sale-indicator'),
                    label: 'Venta',
                    badge: _textBadge(
                      context,
                      prospect.status == 'Venta realizada'
                          ? 'Venta\nrealizada'
                          : 'Sin\nventa',
                      fontSize: 20,
                      height: 0.95,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
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
                          selectedColor: section.ink(palette),
                          labelStyle: TextStyle(
                            fontFamily: 'SulphurPoint',
                            fontSize: 12,
                            color: selected.contains(section.label)
                                ? section.fill(palette)
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
  final int expansionRevision;
  const ProspectDetailPanel({
    super.key,
    required this.title,
    required this.color,
    this.foreground,
    required this.child,
    this.initiallyExpanded = false,
    this.nested = false,
    this.expansionRevision = 0,
  });
  @override
  State<ProspectDetailPanel> createState() => _ProspectDetailPanelState();
}

class _ProspectDetailPanelState extends State<ProspectDetailPanel> {
  late bool _expanded = widget.initiallyExpanded;

  @override
  void didUpdateWidget(covariant ProspectDetailPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.expansionRevision != widget.expansionRevision) {
      _expanded = true;
    }
  }

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
                        fontWeight: FontWeight.w600,
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
                      color: palette.cardArrowFill,
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
