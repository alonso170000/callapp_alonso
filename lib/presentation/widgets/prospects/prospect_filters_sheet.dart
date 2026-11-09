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
            title: Text(
              value,
              style: const TextStyle(fontFamily: 'SulphurPoint', fontSize: 16),
            ),
            contentPadding: EdgeInsets.zero,
            dense: true,
            visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
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
              title: Text(
                value,
                style: const TextStyle(
                  fontFamily: 'SulphurPoint',
                  fontSize: 16,
                ),
              ),
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              dense: true,
              visualDensity: const VisualDensity(vertical: -4, horizontal: -4),
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

  Widget _button(
    String label,
    Color background,
    Color foreground,
    VoidCallback? onPressed,
  ) => Expanded(
    child: FilledButton(
      onPressed: onPressed,
      style: FilledButton.styleFrom(
        backgroundColor: background,
        foregroundColor: foreground,
        minimumSize: const Size.fromHeight(42),
        padding: const EdgeInsets.symmetric(horizontal: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontFamily: 'BebasNeue', fontSize: 18),
        ),
      ),
    ),
  );

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
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _heading('Próximo contacto'),
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
                      _heading('Prioridad'),
                      _checks(ProspectFilters.priorities, _draft.temperatures),
                      _heading('Fecha de asignación'),
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
                      _heading('Resultado del último contacto'),
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
              const SizedBox(height: 18),
              Row(
                children: [
                  _button(
                    'RESTABLECER',
                    palette.secondaryActionFill,
                    palette.secondaryActionForeground,
                    () => setState(() => _draft = ProspectFilters.forSeller()),
                  ),
                  const SizedBox(width: 12),
                  _button(
                    count == 0 ? 'SIN RESULTADOS' : 'VER $count RESULTADOS',
                    palette.brandFill,
                    palette.onBrand,
                    count == 0 ? null : () => Navigator.pop(context, _draft),
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
