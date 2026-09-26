import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

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

  Widget _date(DateTime? date) {
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
                      style: const TextStyle(fontSize: 10),
                    ),
                    Text(
                      '${date.day}'.padLeft(2, '0'),
                      style: const TextStyle(fontSize: 25, height: 1),
                    ),
                  ],
                ),
                Text(
                  '${months[date.month - 1]} ${date.year}',
                  style: const TextStyle(fontSize: 9, height: 1),
                ),
              ],
            ),
    );
  }

  Widget _badge(Widget child) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
    decoration: BoxDecoration(
      color: const Color(0xFF004C49),
      borderRadius: BorderRadius.circular(6),
    ),
    child: DefaultTextStyle(
      style: const TextStyle(
        fontFamily: 'SulphurPoint',
        color: AppColors.homeWarmText,
      ),
      child: child,
    ),
  );
  Widget _group(String label, Widget child) => Column(
    children: [
      FittedBox(fit: BoxFit.scaleDown, child: child),
      const SizedBox(height: 3),
      Text(label, style: const TextStyle(fontSize: 10, color: Colors.white)),
    ],
  );

  @override
  Widget build(BuildContext context) {
    final next = prospect.nextContact;
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 16),
      child: Column(
        children: [
          Row(
            children: [
              const BackButton(color: Colors.white),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      prospect.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'BebasNeue',
                        color: AppColors.homeWarmText,
                        fontSize: 20,
                      ),
                    ),
                    Text(
                      prospect.status.toUpperCase(),
                      style: const TextStyle(
                        fontFamily: 'BebasNeue',
                        color: Colors.white,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              CircleAvatar(
                radius: 18,
                backgroundColor: prospect.avatarColor,
                child: Image.asset('lib/resources/images/Frame.png'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Flexible(
                flex: 5,
                child: _group(
                  'Próximo contacto',
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _date(next),
                      const SizedBox(width: 6),
                      if (next != null)
                        _badge(
                          Column(
                            children: [
                              Text(
                                '${next.hour % 12 == 0 ? 12 : next.hour % 12}:${next.minute.toString().padLeft(2, '0')}',
                                style: const TextStyle(fontSize: 24, height: 1),
                              ),
                              Text(
                                next.hour < 12 ? 'am' : 'pm',
                                style: const TextStyle(fontSize: 9, height: 1),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                flex: 3,
                child: _group(
                  'Fecha de asignación',
                  _date(prospect.assignedAt),
                ),
              ),
              const SizedBox(width: 8),
              _group(
                'Venta',
                _badge(
                  Text(
                    prospect.status == 'Venta realizada' ? 'SÍ' : 'NO',
                    style: const TextStyle(fontSize: 25),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children:
                  [
                        'Seguimiento',
                        'Discovery',
                        'Guiones',
                        'Prospecto',
                        'Historial',
                      ]
                      .map(
                        (name) => Padding(
                          padding: const EdgeInsets.only(right: 5),
                          child: FilterChip(
                            label: Text(name),
                            selected: selected.contains(name),
                            onSelected: (_) => onToggle(name),
                            showCheckmark: false,
                            side: BorderSide.none,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4),
                            ),
                            materialTapTargetSize:
                                MaterialTapTargetSize.shrinkWrap,
                            visualDensity: VisualDensity.compact,
                            padding: EdgeInsets.zero,
                            labelPadding: const EdgeInsets.symmetric(
                              horizontal: 6,
                            ),
                            backgroundColor: const Color(0xFF004F4B),
                            selectedColor: switch (name) {
                              'Discovery' => const Color(0xFF95FF90),
                              'Guiones' => const Color(0xFFFFF47A),
                              'Prospecto' => const Color(0xFFFF929C),
                              _ => const Color(0xFF96E3F4),
                            },
                            labelStyle: TextStyle(
                              fontFamily: 'SulphurPoint',
                              fontSize: 11,
                              color: selected.contains(name)
                                  ? const Color(0xFF185465)
                                  : const Color(0xFF68A6A0),
                            ),
                          ),
                        ),
                      )
                      .toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class ProspectDetailPanel extends StatefulWidget {
  final String title;
  final Color color;
  final Widget child;
  final bool initiallyExpanded;
  final bool nested;
  const ProspectDetailPanel({
    super.key,
    required this.title,
    required this.color,
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
  Widget build(BuildContext context) => Material(
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
                if (widget.title.contains('seguimiento') ||
                    widget.title == 'Datos del prospecto') ...[
                  Icon(
                    Icons.cloud_done,
                    size: 21,
                    color: widget.title == 'Datos del prospecto'
                        ? const Color(0xFFB80009)
                        : widget.nested
                        ? const Color(0xFF48A7BC)
                        : const Color(0xFF398AA0),
                  ),
                  const SizedBox(width: 5),
                ],
                Expanded(
                  child: Text(
                    widget.title,
                    style: TextStyle(
                      fontSize: widget.nested ? 16 : 18,
                      color: widget.nested ? Colors.white : Colors.black,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    _expanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: const Color(0xFF172D33),
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
