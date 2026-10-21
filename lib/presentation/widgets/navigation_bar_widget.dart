import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class NavigationBarWidget extends StatefulWidget {
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<bool>? onSearchVisibilityChanged;
  final ValueChanged<int>? onDestinationSelected;
  final VoidCallback? onAddAgenda;
  final VoidCallback? onAddProspect;
  final int? destinationIndex;

  const NavigationBarWidget({
    super.key,
    this.onSearchChanged,
    this.onSearchVisibilityChanged,
    this.onDestinationSelected,
    this.onAddAgenda,
    this.onAddProspect,
    this.destinationIndex,
  });

  @override
  State<NavigationBarWidget> createState() => _NavigationBarWidgetState();
}

class _NavigationBarWidgetState extends State<NavigationBarWidget> {
  static const Duration _animationDuration = Duration(milliseconds: 600);
  static const Curve _animationCurve = Curves.easeOutCubic;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  int selectedIndex = 0;
  bool _isSearchOpen = false;

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
    _searchController.addListener(_onSearchTextChanged);
  }

  @override
  void didUpdateWidget(covariant NavigationBarWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.destinationIndex != null &&
        widget.destinationIndex != oldWidget.destinationIndex) {
      selectedIndex = widget.destinationIndex!;
    }
  }

  void _onSearchTextChanged() {
    if (mounted) {
      setState(() {});
      widget.onSearchChanged?.call(_searchController.text);
    }
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _openSearch() {
    setState(() {
      _isSearchOpen = true;
      selectedIndex = 0;
    });
    widget.onDestinationSelected?.call(0);
    widget.onSearchVisibilityChanged?.call(true);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_isSearchOpen) return;
      _searchFocusNode.requestFocus();
    });
  }

  void _closeSearch() {
    _searchController.clear();
    setState(() {
      _isSearchOpen = false;
      selectedIndex = 0;
    });
    _searchFocusNode.unfocus();
    widget.onSearchVisibilityChanged?.call(false);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: AnimatedSwitcher(
        duration: _animationDuration,
        switchInCurve: _animationCurve,
        switchOutCurve: Curves.easeInOut,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SizeTransition(
              sizeFactor: animation,
              axis: Axis.horizontal,
              alignment: Alignment.centerRight,
              child: child,
            ),
          );
        },
        child: _isSearchOpen ? _buildSearchBar() : _buildNormalBar(),
      ),
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
        _SearchCircleButton(onTap: _openSearch, size: height),
      ],
    );
  }

  Widget _buildSearchBar() {
    final palette = AppPalette.of(context);
    return Row(
      key: const ValueKey('search-navigation-bar'),
      children: [
        _NavigationSurface(
          width: 64,
          height: 64,
          onTap: _closeSearch,
          semanticLabel: 'Cerrar búsqueda',
          child: Center(
            child: Icon(
              Iconsax.home_2_copy,
              color: palette.navForeground,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _NavigationSurface(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autocorrect: false,
                textInputAction: TextInputAction.search,
                cursorColor: palette.navForeground,
                style: TextStyle(color: palette.navForeground, fontSize: 16),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Buscar prospecto...',
                  hintStyle: TextStyle(
                    color: palette.navForeground,
                    fontSize: 15,
                  ),
                  prefixIcon: Icon(
                    Iconsax.search_normal_1_copy,
                    color: palette.navForeground,
                    size: 24,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 24,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _searchController.clear,
                          child: Icon(
                            Icons.close_rounded,
                            color: palette.navForeground,
                            size: 22,
                          ),
                        )
                      : null,
                  suffixIconConstraints: const BoxConstraints(
                    minWidth: 28,
                    minHeight: 24,
                  ),
                ),
              ),
            ),
          ),
        ),
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
                    fontSize: 16,
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
  final VoidCallback onTap;
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
