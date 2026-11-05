import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class AgendaProspectOption<T> {
  final T value;
  final String label;

  const AgendaProspectOption({required this.value, required this.label});
}

class AgendaProspectSelector<T> extends StatelessWidget {
  final T value;
  final List<AgendaProspectOption<T>> options;
  final ValueChanged<T> onChanged;
  final FormFieldValidator<T>? validator;
  final String searchHint;

  const AgendaProspectSelector({
    super.key,
    required this.value,
    required this.options,
    required this.onChanged,
    this.validator,
    this.searchHint = 'Buscar prospecto',
  });

  String _labelFor(T selected) =>
      options.firstWhere((option) => option.value == selected).label;

  Future<T?> _showOptions(BuildContext context) => showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (context) => _ProspectOptionsSheet<T>(
      options: options,
      selected: value,
      searchHint: searchHint,
    ),
  );

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return FormField<T>(
      initialValue: value,
      validator: validator,
      builder: (field) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(9),
            onTap: () async {
              final selected = await _showOptions(context);
              if (selected == null || !context.mounted) return;
              field.didChange(selected);
              onChanged(selected);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                filled: true,
                fillColor: palette.brandFill,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                border: const OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(9)),
                  borderSide: BorderSide.none,
                ),
                errorText: field.errorText,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _labelFor(field.value ?? value),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: palette.onBrand,
                        fontFamily: 'SulphurPoint',
                        fontSize: 16,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    color: palette.onBrand,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ProspectOptionsSheet<T> extends StatefulWidget {
  final List<AgendaProspectOption<T>> options;
  final T selected;
  final String searchHint;

  const _ProspectOptionsSheet({
    required this.options,
    required this.selected,
    required this.searchHint,
  });

  @override
  State<_ProspectOptionsSheet<T>> createState() =>
      _ProspectOptionsSheetState<T>();
}

class _ProspectOptionsSheetState<T> extends State<_ProspectOptionsSheet<T>> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    final normalized = _query.trim().toLowerCase();
    final visible = normalized.isEmpty
        ? widget.options
        : widget.options
              .where(
                (option) => option.label.toLowerCase().contains(normalized),
              )
              .toList();

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        top: 12,
        right: 20,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 16,
      ),
      child: SizedBox(
        height: MediaQuery.sizeOf(context).height * 0.65,
        child: Column(
          children: [
            Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.outline,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              key: const ValueKey('agenda-prospect-search'),
              controller: _search,
              autofocus: true,
              textInputAction: TextInputAction.search,
              onChanged: (value) => setState(() => _query = value),
              decoration: InputDecoration(
                hintText: widget.searchHint,
                prefixIcon: const Icon(Iconsax.search_normal_1_copy),
                suffixIcon: _query.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpiar búsqueda',
                        onPressed: () {
                          _search.clear();
                          setState(() => _query = '');
                        },
                        icon: const Icon(Icons.close_rounded),
                      ),
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: visible.isEmpty
                  ? const Center(child: Text('No se encontraron prospectos'))
                  : ListView.builder(
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      itemCount: visible.length,
                      itemBuilder: (context, index) {
                        final option = visible[index];
                        final selected = option.value == widget.selected;
                        return ListTile(
                          title: Text(option.label, style: TextStyle(fontSize: 16)),
                          trailing: selected
                              ? Icon(
                                  Icons.check_rounded,
                                  color: palette.brandFill,
                                )
                              : null,
                          onTap: () => Navigator.pop(context, option.value),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
