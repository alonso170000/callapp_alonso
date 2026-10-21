import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/agenda_filters.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';

class AgendaFiltersSheet extends StatefulWidget {
  final AgendaFilters initial;
  final List<String> prospects;
  final int Function(AgendaFilters) count;
  const AgendaFiltersSheet({
    super.key,
    required this.initial,
    required this.prospects,
    required this.count,
  });
  @override
  State<AgendaFiltersSheet> createState() => _AgendaFiltersSheetState();
}

class _AgendaFiltersSheetState extends State<AgendaFiltersSheet> {
  late AgendaFilters _draft = widget.initial.copy();
  Widget _heading(String label) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 4),
    child: Text(
      label,
      style: const TextStyle(
        fontFamily: 'SulphurPoint',
        fontSize: 19,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
  Widget _check(String label, bool selected, ValueChanged<bool> change) {
    final scheme = Theme.of(context).colorScheme;
    return CheckboxListTile(
      title: Text(
        label,
        style: const TextStyle(fontFamily: 'SulphurPoint', fontSize: 16),
      ),
      value: selected,
      onChanged: (value) => setState(() => change(value!)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
      activeColor: scheme.primary,
      checkColor: scheme.onPrimary,
      side: BorderSide(color: scheme.outline),
    );
  }

  Widget _button(String label, Color color, VoidCallback onPressed) => Expanded(
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        minimumSize: const Size.fromHeight(42),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(fontFamily: 'BebasNeue', fontSize: 18),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 18),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const SizedBox(width: 48),
                const Expanded(
                  child: Text(
                    'Filtros',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontFamily: 'SulphurPoint',
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar filtros',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 28),
                ),
              ],
            ),
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _heading('Tipo de actividad'),
                    for (final type in AgendaFilters.types)
                      _check(
                        type,
                        _draft.selectedTypes.contains(type),
                        (value) => value
                            ? _draft.selectedTypes.add(type)
                            : _draft.selectedTypes.remove(type),
                      ),
                    _heading('Estado'),
                    for (final entry in {
                      AgendaStatus.pending: 'Pendiente',
                      AgendaStatus.overdue: 'Atrasada',
                      AgendaStatus.completed: 'Completada',
                      AgendaStatus.cancelled: 'Cancelada',
                    }.entries)
                      _check(
                        entry.value,
                        _draft.statuses.contains(entry.key),
                        (value) => value
                            ? _draft.statuses.add(entry.key)
                            : _draft.statuses.remove(entry.key),
                      ),
                    _heading('Prospecto'),
                    DropdownButtonFormField<String>(
                      key: ValueKey(_draft.prospect),
                      initialValue: _draft.prospect ?? '',
                      isExpanded: true,
                      dropdownColor: palette.brandFill,
                      iconEnabledColor: palette.onBrand,
                      style: TextStyle(
                        fontFamily: 'SulphurPoint',
                        fontSize: 18,
                        color: palette.onBrand,
                      ),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: palette.brandFill,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        border: const OutlineInputBorder(
                          borderRadius: BorderRadius.all(Radius.circular(9)),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      items: [
                        const DropdownMenuItem(
                          value: '',
                          child: Text('Todos los prospectos'),
                        ),
                        for (final prospect in widget.prospects)
                          DropdownMenuItem(
                            value: prospect,
                            child: Text(
                              prospect,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                      onChanged: (value) => setState(
                        () => _draft.prospect = value == '' ? null : value,
                      ),
                    ),
                    _heading('Horario'),
                    RadioGroup<AgendaTimeFilter>(
                      groupValue: _draft.time,
                      onChanged: (value) =>
                          setState(() => _draft.time = value!),
                      child: Column(
                        children: [
                          for (final entry in {
                            AgendaTimeFilter.all: 'Todo el día',
                            AgendaTimeFilter.morning: 'Mañana',
                            AgendaTimeFilter.afternoon: 'Tarde',
                          }.entries)
                            RadioListTile<AgendaTimeFilter>(
                              value: entry.key,
                              title: Text(
                                entry.value,
                                style: const TextStyle(
                                  fontFamily: 'SulphurPoint',
                                  fontSize: 16,
                                ),
                              ),
                              activeColor: Theme.of(context)
                                  .colorScheme
                                  .primary,
                              contentPadding: EdgeInsets.zero,
                              dense: true,
                              visualDensity: const VisualDensity(
                                vertical: -4,
                                horizontal: -4,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                _button(
                  'LIMPIAR FILTROS',
                  const Color(0xFF696969),
                  () => setState(() => _draft = AgendaFilters()),
                ),
                const SizedBox(width: 12),
                _button(
                  'VER ${widget.count(_draft)} RESULTADOS',
                  const Color(0xFF008FA0),
                  () => Navigator.pop(context, _draft),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
