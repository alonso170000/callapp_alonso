import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_dashboard_widgets.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';

class ProspectsScreen extends StatefulWidget {
  const ProspectsScreen({super.key});

  @override
  State<ProspectsScreen> createState() => _ProspectsScreenState();
}

class _ProspectsScreenState extends State<ProspectsScreen> {
  static const _filters = [
    'Todos',
    'Atrasados',
    'Nuevo',
    'Contactado y validado',
    'Seguimiento',
    'Cotización',
    'Negociación',
    'Venta realizada',
  ];
  final _search = TextEditingController();
  String _status = 'Todos';
  String _temperature = 'Todos';
  String _sort = 'Último contacto';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  String _normalize(String value) {
    var result = value.toLowerCase();
    const accents = {'á': 'a', 'é': 'e', 'í': 'i', 'ó': 'o', 'ú': 'u'};
    accents.forEach((key, value) => result = result.replaceAll(key, value));
    return result;
  }

  List<ProspectRecord> get _visible {
    final query = _normalize(_search.text.trim());
    final result = demoProspects
        .where(
          (p) =>
              (_status == 'Todos' || p.status == _status) &&
              (_temperature == 'Todos' || p.temperature == _temperature) &&
              _normalize('${p.name} ${p.phone} ${p.email}').contains(query),
        )
        .toList();
    result.sort((a, b) {
      if (_sort == 'Nombre') {
        return _normalize(a.name).compareTo(_normalize(b.name));
      }
      if (_sort == 'Próxima cita') {
        return a.appointment.compareTo(b.appointment);
      }
      final contact = a.daysSinceContact.compareTo(b.daysSinceContact);
      return contact != 0 ? contact : a.appointment.compareTo(b.appointment);
    });
    return result;
  }

  Future<void> _showFilters() async {
    final selection = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.homeBackground,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'TEMPERATURA DEL PROSPECTO',
                style: TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 26,
                  color: AppColors.primaryColor,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                children: ['Todos', 'Caliente', 'Tibio', 'Frío']
                    .map(
                      (value) => ChoiceChip(
                        label: Text(value),
                        selected: _temperature == value,
                        onSelected: (_) => Navigator.pop(context, value),
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
      ),
    );
    if (selection != null && mounted) setState(() => _temperature = selection);
  }

  @override
  Widget build(BuildContext context) {
    final prospects = _visible;
    return CustomScrollView(
      key: const PageStorageKey('prospects-list'),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const HomeHeader(
                  userName: 'Leonardo Pérez',
                  title: 'TUS PROSPECTOS',
                ),
                const SizedBox(height: 22),
                TextField(
                  controller: _search,
                  onChanged: (_) => setState(() {}),
                  style: const TextStyle(
                    fontFamily: 'SulphurPoint',
                    fontSize: 14,
                    color: AppColors.primaryColor,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, teléfono o email...',
                    hintStyle: const TextStyle(
                      fontFamily: 'SulphurPoint',
                      fontSize: 13,
                      color: Color(0xFF5CABA4),
                    ),
                    filled: true,
                    fillColor: const Color(0xFFC5E9E3),
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    prefixIcon: const Icon(
                      Iconsax.search_normal_1_copy,
                      color: AppColors.primaryColor,
                      size: 23,
                    ),
                    suffixIcon: Padding(
                      padding: const EdgeInsets.all(6),
                      child: IconButton.filled(
                        tooltip: 'Filtrar por temperatura',
                        style: IconButton.styleFrom(
                          backgroundColor: AppColors.primaryColor,
                          foregroundColor: _temperature == 'Todos'
                              ? Colors.white
                              : AppColors.accentColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        onPressed: _showFilters,
                        icon: const Icon(Icons.tune_rounded, size: 20),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: _filters
                      .map(
                        (filter) => ChoiceChip(
                          label: Text(filter),
                          selected: _status == filter,
                          showCheckmark: false,
                          onSelected: (_) => setState(() => _status = filter),
                          selectedColor: AppColors.primaryColor,
                          backgroundColor: const Color(0xFFABF5E7),
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(5),
                          ),
                          materialTapTargetSize:
                              MaterialTapTargetSize.shrinkWrap,
                          visualDensity: VisualDensity.compact,
                          labelPadding: const EdgeInsets.symmetric(
                            horizontal: 5,
                          ),
                          labelStyle: TextStyle(
                            fontFamily: 'SulphurPoint',
                            fontSize: 12,
                            color: _status == filter
                                ? Colors.white
                                : const Color(0xFF3B8C83),
                          ),
                        ),
                      )
                      .toList(),
                ),
                if (_temperature != 'Todos')
                  Align(
                    alignment: Alignment.centerLeft,
                    child: InputChip(
                      label: Text(_temperature),
                      onDeleted: () => setState(() => _temperature = 'Todos'),
                    ),
                  ),
                const SizedBox(height: 12),
                Wrap(
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    Text(
                      'MOSTRANDO ${prospects.length} PROSPECTOS',
                      style: const TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 16,
                        color: AppColors.primaryColor,
                      ),
                    ),
                    PopupMenuButton<String>(
                      tooltip: 'Ordenar prospectos',
                      initialValue: _sort,
                      onSelected: (value) => setState(() => _sort = value),
                      itemBuilder: (_) =>
                          ['Último contacto', 'Nombre', 'Próxima cita']
                              .map(
                                (value) => PopupMenuItem(
                                  value: value,
                                  child: Text(value),
                                ),
                              )
                              .toList(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFABF5E7),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                'Ordenar por ${_sort.toLowerCase()}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontFamily: 'SulphurPoint',
                                  fontSize: 12,
                                  color: AppColors.primaryColor,
                                ),
                              ),
                            ),
                            const Icon(
                              Icons.keyboard_arrow_down,
                              color: AppColors.primaryColor,
                              size: 18,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
              ],
            ),
          ),
        ),
        if (prospects.isEmpty)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
              child: Column(
                children: [
                  const Icon(
                    Iconsax.search_normal_1_copy,
                    size: 40,
                    color: AppColors.primaryColor,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'No se encontraron prospectos',
                    style: TextStyle(
                      fontFamily: 'SulphurPoint',
                      fontSize: 18,
                      color: AppColors.primaryColor,
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _search.clear();
                      _status = 'Todos';
                      _temperature = 'Todos';
                    }),
                    child: const Text('Limpiar filtros'),
                  ),
                ],
              ),
            ),
          ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 118),
          sliver: SliverList.builder(
            itemCount: prospects.length,
            itemBuilder: (_, index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ProspectCard(prospect: prospects[index]),
            ),
          ),
        ),
      ],
    );
  }
}

class _ProspectCard extends StatelessWidget {
  final ProspectRecord prospect;
  const _ProspectCard({required this.prospect});

  Future<void> _contact(BuildContext context, bool message) async {
    await showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.homeBackground,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                prospect.name.toUpperCase(),
                style: const TextStyle(
                  fontFamily: 'BebasNeue',
                  fontSize: 28,
                  color: AppColors.primaryColor,
                ),
              ),
              Text(
                message ? 'Datos para enviar un mensaje' : 'Datos para llamar',
                style: const TextStyle(
                  fontFamily: 'SulphurPoint',
                  fontSize: 18,
                ),
              ),
              const SizedBox(height: 12),
              SelectableText(prospect.phone),
              if (message) SelectableText(prospect.email),
              const SizedBox(height: 12),
              const Text(
                'Contacto de ejemplo',
                style: TextStyle(color: Colors.black54),
              ),
              TextButton.icon(
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: prospect.phone));
                  if (context.mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Número copiado')),
                    );
                  }
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copiar teléfono'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final date = prospect.appointment;
    String two(int value) => value.toString().padLeft(2, '0');
    final temperatureColor = switch (prospect.temperature) {
      'Caliente' => const Color(0xFFFF535C),
      'Tibio' => const Color(0xFFFFCC44),
      _ => const Color(0xFF25C3E0),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: prospect.avatarColor,
                child: Image.asset(
                  'lib/resources/images/Frame.png',
                  width: 28,
                  height: 28,
                  excludeFromSemantics: true,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      prospect.name.toUpperCase(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'BebasNeue',
                        fontSize: 21,
                        height: 1.05,
                        color: AppColors.homeWarmText,
                      ),
                    ),
                    Text(
                      'Llamada · Hace ${prospect.daysSinceContact} ${prospect.daysSinceContact == 1 ? 'día' : 'días'}',
                      style: const TextStyle(
                        fontFamily: 'SulphurPoint',
                        fontSize: 10,
                        color: Color(0xFFB0E4DB),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              _action(
                context,
                message: true,
                color: const Color(0xFF64FF98),
                icon: Iconsax.message_copy,
              ),
              const SizedBox(width: 6),
              _action(
                context,
                message: false,
                color: const Color(0xFFFFE18A),
                icon: Iconsax.call_copy,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            prospect.note,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontFamily: 'SulphurPoint',
              fontSize: 13,
              height: 1.2,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              _tag(
                prospect.status == 'Atrasados'
                    ? 'ATRASADO'
                    : prospect.status.toUpperCase(),
                prospect.statusColor,
              ),
              _tag(
                prospect.temperature.toUpperCase(),
                temperatureColor,
                foreground: Colors.white,
              ),
              _tag(
                '${two(date.day)}-${two(date.month)}-${date.year}',
                const Color(0xFFA8F5E4),
              ),
              _tag(
                '${two(date.hour % 12 == 0 ? 12 : date.hour % 12)}:${two(date.minute)} ${date.hour < 12 ? 'AM' : 'PM'}',
                prospect.status == 'Atrasados'
                    ? const Color(0xFFFFA3A6)
                    : const Color(0xFFA8F5E4),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _action(
    BuildContext context, {
    required bool message,
    required Color color,
    required IconData icon,
  }) {
    return IconButton(
      tooltip: message
          ? 'Mensaje a ${prospect.name}'
          : 'Llamar a ${prospect.name}',
      onPressed: () => _contact(context, message),
      style: IconButton.styleFrom(
        backgroundColor: color,
        foregroundColor: AppColors.primaryColor,
        minimumSize: const Size(34, 34),
        maximumSize: const Size(34, 34),
        padding: EdgeInsets.zero,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
      ),
      icon: Icon(icon, size: 19),
    );
  }

  Widget _tag(String text, Color color, {Color foreground = Colors.black}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      color: color,
      child: Text(
        text,
        style: TextStyle(
          fontFamily: 'BebasNeue',
          fontSize: 13,
          height: 1.1,
          color: foreground,
        ),
      ),
    );
  }
}
