import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/models/prospect_filters.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class ProspectFiltersSheet extends StatefulWidget {
  final ProspectFilters initial;
  final int Function(ProspectFilters) count;
  const ProspectFiltersSheet({
    super.key,
    required this.initial,
    required this.count,
  });
  @override
  State<ProspectFiltersSheet> createState() => _ProspectFiltersSheetState();
}

class _ProspectFiltersSheetState extends State<ProspectFiltersSheet> {
  late ProspectFilters _draft = widget.initial.copy();

  Widget _title(String text) => Padding(
    padding: const EdgeInsets.only(top: 18, bottom: 4),
    child: Text(
      text,
      style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
    ),
  );

  Widget _options(
    List<String> options,
    String? selected,
    ValueChanged<String?> onChanged,
  ) => RadioGroup<String>(
    groupValue: selected,
    onChanged: onChanged,
    child: Column(
      children: options
          .map(
            (value) => RadioListTile<String>(
              value: value,
              title: Text(value),
              dense: true,
              contentPadding: EdgeInsets.zero,
              visualDensity: const VisualDensity(vertical: -3),
              activeColor: AppColors.primaryColor,
              toggleable: true,
            ),
          )
          .toList(),
    ),
  );

  Widget _checks(List<String> options, Set<String> selected) => Column(
    children: options
        .map(
          (value) => CheckboxListTile(
            value: selected.contains(value),
            title: Text(value),
            dense: true,
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            visualDensity: const VisualDensity(vertical: -3),
            activeColor: AppColors.primaryColor,
            onChanged: (checked) => setState(() {
              checked! ? selected.add(value) : selected.remove(value);
            }),
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
    final now = DateTime.now();
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 5, 12, 31),
      initialDateRange: _draft.range,
      helpText: 'Fecha de asignación',
      saveText: 'Guardar',
    );
    if (mounted && range != null) {
      setState(() {
        _draft.assignment = value;
        _draft.range = range;
      });
    }
  }

  @override
  Widget build(BuildContext context) => Theme(
    data: Theme.of(context).copyWith(
      textTheme: Theme.of(context).textTheme
          .apply(fontFamily: 'SulphurPoint', bodyColor: Colors.black),
    ),
    child: SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
        child: Column(
          children: [
            Row(
              children: [
                const SizedBox(width: 48),
                const Expanded(
                  child: Text(
                    'Filtros',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 22),
                  ),
                ),
                IconButton(
                  tooltip: 'Cerrar filtros',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _title('Próximo contacto'),
                    _options(
                      ['Hoy', 'Mañana', 'Esta semana', 'Sin programar'],
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
                      TextButton(
                        onPressed: () => _assignment('Rango personalizado'),
                        child: Text(
                          '${_draft.range!.start.day}/${_draft.range!.start.month}/${_draft.range!.start.year} - ${_draft.range!.end.day}/${_draft.range!.end.month}/${_draft.range!.end.year}',
                        ),
                      ),
                    _title('Resultado del último contacto'),
                    _checks(ProspectFilters.outcomes, _draft.results),
                    _title('Ordenar por'),
                    _options(
                      ProspectFilters.sorts,
                      _draft.sort,
                      (value) => setState(
                        () => _draft.sort = value ?? 'Último contacto',
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF606060),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => setState(() => _draft = ProspectFilters()),
                    child: const Text(
                      'LIMPIAR FILTROS',
                      style: TextStyle(fontFamily: 'BebasNeue', fontSize: 18),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF008593),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                    onPressed: () => Navigator.pop(context, _draft),
                    child: Text(
                      'VER ${widget.count(_draft)} RESULTADOS',
                      style: const TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 18,
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
