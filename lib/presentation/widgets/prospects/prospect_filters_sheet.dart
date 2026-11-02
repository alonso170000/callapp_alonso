import 'package:callerapp_frontend/presentation/models/prospect_filters.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:flutter/material.dart';

class ProspectFiltersSheet extends StatefulWidget {
  const ProspectFiltersSheet({
    super.key,
    required this.initial,
    required this.count,
    this.now,
  });

  final ProspectFilters initial;
  final int Function(ProspectFilters) count;
  final DateTime Function()? now;

  @override
  State<ProspectFiltersSheet> createState() => _ProspectFiltersSheetState();
}

class _ProspectFiltersSheetState extends State<ProspectFiltersSheet> {
  late ProspectFilters _draft = widget.initial.copy();

  DateTime get _now => (widget.now ?? businessNow)();
  int get _count => widget.count(_draft);

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.bold,
        fontFamily: 'SulphurPoint',
      ),
    ),
  );

  Widget _options(
    List<String> options,
    String? selected,
    ValueChanged<String?> onChanged,
  ) => RadioGroup<String>(
    groupValue: selected ?? 'Cualquiera',
    onChanged: (value) => onChanged(value == 'Cualquiera' ? null : value),
    child: Column(
      children: ['Cualquiera', ...options].map((value) {
        return Semantics(
          label: value,
          checked: (selected ?? 'Cualquiera') == value,
          child: RadioListTile<String>(
            value: value,
            title: Text(value),
            dense: true,
            contentPadding: EdgeInsets.zero,
            visualDensity: const VisualDensity(vertical: -1),
            activeColor: Theme.of(context).colorScheme.primary,
          ),
        );
      }).toList(),
    ),
  );

  Widget _checks(List<String> options, Set<String> selected) => Column(
    children: options
        .map(
          (value) => Semantics(
            label: value,
            checked: selected.contains(value),
            child: CheckboxListTile(
              value: selected.contains(value),
              title: Text(value),
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              visualDensity: const VisualDensity(vertical: -1),
              activeColor: Theme.of(context).colorScheme.primary,
              checkColor: Theme.of(context).colorScheme.onPrimary,
              side: BorderSide(color: Theme.of(context).colorScheme.outline),
              onChanged: (checked) => setState(
                () => checked! ? selected.add(value) : selected.remove(value),
              ),
            ),
          ),
        )
        .toList(),
  );

  Future<void> _assignment(String? value) async {
    if (value != 'Rango personalizado') {
      setState(() {
        _draft.assignment = value;
        _draft.range = null;
      });
      return;
    }
    final now = _now;
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: _draft.range,
      helpText: 'Fecha de asignación',
      saveText: 'Guardar',
      builder: (context, child) => SafeArea(
        child: Theme(
          data: Theme.of(context).copyWith(
            appBarTheme: const AppBarTheme(toolbarHeight: 56),
            datePickerTheme: Theme.of(context).datePickerTheme.copyWith(
              rangePickerHeaderBackgroundColor: AppPalette.of(context)
                  .brandFill,
              rangePickerHeaderForegroundColor: AppPalette.of(context).onBrand,
              rangePickerHeaderHeadlineStyle: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: MediaQuery.sizeOf(context).width < 360 ? 20 : 24,
              ),
              rangePickerHeaderHelpStyle: const TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 14,
              ),
            ),
          ),
          child: child!,
        ),
      ),
    );
    if (mounted && range != null) {
      setState(() {
        _draft.assignment = value;
        _draft.range = range;
      });
    }
  }

  String _date(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final count = _count;
    return Theme(
      data: Theme.of(context).copyWith(
        textTheme: Theme.of(context).textTheme.apply(
          fontFamily: 'SulphurPoint',
          bodyColor: Theme.of(context).colorScheme.onSurface,
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
          child: Column(
            children: [
              Row(
                children: [
                  const SizedBox(width: 48),
                  Expanded(
                    child: Column(
                      children: [
                        const Text(
                          'Filtros',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 22),
                        ),
                        Text(
                          '$count resultados',
                          style: const TextStyle(fontSize: 14),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Cerrar filtros',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Wrap(
                spacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('Por atender'),
                    selected: _draft.isSellerPreset,
                    selectedColor: palette.chipSelectedFill,
                    labelStyle: TextStyle(
                      color: _draft.isSellerPreset
                          ? palette.chipSelectedForeground
                          : palette.chipForeground,
                    ),
                    onSelected: (_) =>
                        setState(() => _draft = ProspectFilters.forSeller()),
                  ),
                  ChoiceChip(
                    label: const Text('Todos'),
                    selected: _draft.isAllPreset,
                    selectedColor: palette.chipSelectedFill,
                    labelStyle: TextStyle(
                      color: _draft.isAllPreset
                          ? palette.chipSelectedForeground
                          : palette.chipForeground,
                    ),
                    onSelected: (_) =>
                        setState(() => _draft = ProspectFilters.all()),
                  ),
                ],
              ),
              Expanded(
                child: SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _title('Próximo contacto'),
                      _options(
                        [
                          'Contacto vencido',
                          'Hoy',
                          'Mañana',
                          'Esta semana',
                          'Sin programar',
                        ],
                        _draft.nextContact,
                        (value) => setState(() => _draft.nextContact = value),
                      ),
                      _title('Prioridad'),
                      _checks(ProspectFilters.priorities, _draft.temperatures),
                      _title('Fecha de asignación'),
                      _options(
                        [
                          'Hoy',
                          'Ayer',
                          'Últimos 7 días',
                          'Últimos 30 días',
                          'Rango personalizado',
                        ],
                        _draft.assignment,
                        _assignment,
                      ),
                      if (_draft.range != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 8),
                          child: InputChip(
                            tooltip: 'Cambiar rango',
                            label: Text(
                              '${_date(_draft.range!.start)} – ${_date(_draft.range!.end)}',
                            ),
                            backgroundColor: palette.chipFill,
                            labelStyle: TextStyle(
                              color: palette.chipForeground,
                            ),
                            deleteIcon: const Icon(Icons.close_rounded),
                            deleteIconColor: palette.chipForeground,
                            deleteButtonTooltipMessage: 'Quitar rango',
                            onPressed: () => _assignment('Rango personalizado'),
                            onDeleted: () =>
                                setState(() => _draft.range = null),
                          ),
                        ),
                      _title('Resultado del último contacto'),
                      _checks(ProspectFilters.outcomes, _draft.results),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
              if (count == 0)
                const Padding(
                  padding: EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Ajusta la selección para ver prospectos',
                    textAlign: TextAlign.center,
                  ),
                ),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      style: TextButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: palette.secondaryActionFill,
                        foregroundColor: palette.secondaryActionForeground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onPressed: () =>
                          setState(() => _draft = ProspectFilters.forSeller()),
                      child: const Text(
                        'RESTABLECER',
                        style: TextStyle(fontFamily: 'BebasNeue', fontSize: 17),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      style: FilledButton.styleFrom(
                        minimumSize: const Size(0, 48),
                        backgroundColor: palette.brandFill,
                        foregroundColor: palette.onBrand,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                      ),
                      onPressed: count == 0
                          ? null
                          : () => Navigator.pop(context, _draft),
                      child: FittedBox(
                        child: Text(
                          count == 0
                              ? 'SIN RESULTADOS'
                              : 'VER $count RESULTADOS',
                          style: const TextStyle(
                            fontFamily: 'BebasNeue',
                            fontSize: 17,
                          ),
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
  }
}
