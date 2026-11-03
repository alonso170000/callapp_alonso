import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class NavigationBarWidget extends StatefulWidget {
  final ValueChanged<int>? onDestinationSelected;
  final VoidCallback? onAddAgenda;
  final VoidCallback? onAddProspect;
  final VoidCallback? onSearchTap;
  final int? destinationIndex;

  const NavigationBarWidget({
    super.key,
    this.onDestinationSelected,
    this.onAddAgenda,
    this.onAddProspect,
    this.onSearchTap,
    this.destinationIndex,
  });

  @override
  State<NavigationBarWidget> createState() => _NavigationBarWidgetState();
}

class _NavigationBarWidgetState extends State<NavigationBarWidget> {
  int selectedIndex = 0;

  final List<_NavigationItem> itemsNoSelected = const [
    _NavigationItem(icon: Iconsax.home_2_copy, label: 'Inicio'),
    _NavigationItem(icon: Iconsax.profile_2user_copy, label: 'Prospectos'),
    _NavigationItem(icon: Iconsax.calendar_2_copy, label: 'Agenda'),
    _NavigationItem(icon: Iconsax.profile_circle_copy, label: 'Perfil'),
  ];

  final List<_NavigationItem> itemsSelected = const [
    _NavigationItem(icon: Iconsax.home_2, label: 'Inicio'),
    _NavigationItem(icon: Iconsax.profile_2user, label: 'Prospectos'),
    _NavigationItem(icon: Iconsax.calendar_2, label: 'Agenda'),
    _NavigationItem(icon: Iconsax.profile_circle, label: 'Perfil'),
  ];

  @override
  void initState() {
    super.initState();
    selectedIndex = widget.destinationIndex ?? 0;
  }

  @override
  void didUpdateWidget(covariant NavigationBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destinationIndex != null &&
        widget.destinationIndex != oldWidget.destinationIndex) {
      selectedIndex = widget.destinationIndex!;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: _buildNormalBar(),
    );
  }

  Widget _buildNormalBar() {
    final addAction = selectedIndex == 1
        ? widget.onAddProspect
        : selectedIndex == 2
        ? widget.onAddAgenda
        : null;
    final compact = MediaQuery.sizeOf(context).width < 360 && addAction != null;
    final height = compact ? 52.0 : 64.0;
    return Row(
      key: const ValueKey('normal-navigation-bar'),
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (addAction != null) ...[
          _AddAgendaButton(
            onTap: addAction,
            size: height,
            label: selectedIndex == 1
                ? 'Agregar prospecto'
                : 'Agendar nueva actividad',
          ),
          SizedBox(width: compact ? 6 : 8),
        ],
        Flexible(
          child: _NavigationSurface(
            height: height,
            width: 258,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: compact ? 2 : 4,

              children: List.generate(itemsSelected.length, (index) {
                final itemsSelec = itemsSelected[index];
                final itemsNoSelec = itemsNoSelected[index];
                final isSelected = selectedIndex == index;

                final option = GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () {
                    setState(() {
                      selectedIndex = index;
                    });
                    widget.onDestinationSelected?.call(index);
                  },
                  child: _NavigationOption(
                    itemsSelected: itemsSelec,
                    itemsNoSelected: itemsNoSelec,
                    isSelected: isSelected,
                  ),
                );

                return isSelected
                    ? Expanded(child: option)
                    : SizedBox(width: compact ? 40 : 35, child: option);
              }),
            ),
          ),
        ),
        SizedBox(width: compact ? 6 : 8),
        _SearchCircleButton(onTap: widget.onSearchTap, size: height),
      ],
    );
  }
}

class _NavigationOption extends StatelessWidget {
  final _NavigationItem itemsNoSelected;
  final _NavigationItem itemsSelected;
  final bool isSelected;

  const _NavigationOption({
    required this.itemsNoSelected,
    required this.itemsSelected,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return Semantics(
      selected: isSelected,
      button: true,
      label: itemsSelected.label,
      excludeSemantics: true,
      child: Container(
        height: 50,
        margin: const EdgeInsets.symmetric(horizontal: 2),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? 6 : 0,
          vertical: 4,
        ),
        decoration: BoxDecoration(
          color: isSelected ? palette.navSelectedFill : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? itemsSelected.icon : itemsNoSelected.icon,
              color: isSelected
                  ? palette.navSelectedForeground
                  : palette.navForeground,
              size: 26,
            ),
            if (isSelected) const SizedBox(width: 3),
            if (isSelected)
              Flexible(
                child: Text(
                  itemsSelected.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.navSelectedForeground,
                    fontFamily: 'SulphurPoint',
                    fontSize: 14,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _SearchCircleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final double size;

  const _SearchCircleButton({required this.onTap, this.size = 64});

  @override
  Widget build(BuildContext context) {
    return _NavigationSurface(
      width: size,
      height: size,
      onTap: onTap,
      semanticLabel: 'Buscar prospectos',
      child: Center(
        child: Icon(
          Iconsax.search_normal_1_copy,
          color: AppPalette.of(context).navForeground,
          size: 30,
        ),
      ),
    );
  }
}

class _AddAgendaButton extends StatelessWidget {
  final VoidCallback onTap;
  final double size;
  final String label;

  const _AddAgendaButton({
    required this.onTap,
    this.size = 64,
    this.label = 'Agendar nueva actividad',
  });

  @override
  Widget build(BuildContext context) {
    return _NavigationSurface(
      width: size,
      height: size,
      onTap: onTap,
      semanticLabel: label,
      child: Center(
        child: Icon(
          Iconsax.add_copy,
          color: AppPalette.of(context).navForeground,
          size: 40,
        ),
      ),
    );
  }
}

class _NavigationItem {
  final IconData icon;
  final String label;

  const _NavigationItem({required this.icon, required this.label});
}

class _NavigationSurface extends StatelessWidget {
  final Widget child;
  final double? width;
  final double height;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;

  const _NavigationSurface({
    required this.child,
    this.width,
    required this.height,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(32);
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: Colors.transparent,
          borderRadius: radius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppPalette.of(context).navGradient,
              borderRadius: radius,
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: radius,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
