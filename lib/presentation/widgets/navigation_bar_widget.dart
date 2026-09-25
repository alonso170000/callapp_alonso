import 'package:flutter/material.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class NavigationBarWidget extends StatefulWidget {
  final ValueChanged<String>? onSearchChanged;
  final ValueChanged<bool>? onSearchVisibilityChanged;
  final ValueChanged<int>? onDestinationSelected;

  const NavigationBarWidget({
    super.key,
    this.onSearchChanged,
    this.onSearchVisibilityChanged,
    this.onDestinationSelected,
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
    _searchController.addListener(_onSearchTextChanged);
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
      padding: EdgeInsets.symmetric(
        horizontal: AppStyles.spacingLarge(context),
      ),
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
    return Row(
      key: const ValueKey('normal-navigation-bar'),
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: _NavigationSurface(
            height: 64,
            width: 280,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,

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

                return Expanded(flex: isSelected ? 3 : 1, child: option);
              }),
            ),
          ),
        ),
        const SizedBox(width: 10),
        _SearchCircleButton(onTap: _openSearch),
      ],
    );
  }

  Widget _buildSearchBar() {
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
              color: AppColors.primaryColor,
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
                cursorColor: AppColors.primaryColor,
                style: const TextStyle(
                  color: AppColors.primaryColor,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Buscar prospecto...',
                  hintStyle: const TextStyle(
                    color: AppColors.primaryColor,
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(
                    Iconsax.search_normal_1_copy,
                    color: AppColors.primaryColor,
                    size: 24,
                  ),
                  prefixIconConstraints: const BoxConstraints(
                    minWidth: 34,
                    minHeight: 24,
                  ),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? GestureDetector(
                          onTap: _searchController.clear,
                          child: const Icon(
                            Icons.close_rounded,
                            color: AppColors.primaryColor,
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
          color: isSelected ? AppColors.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? itemsSelected.icon : itemsNoSelected.icon,
              color: isSelected
                  ? AppColors.accentColor
                  : AppColors.primaryColor,
              size: 26,
            ),
            if (isSelected) const SizedBox(width: 3),
            if (isSelected)
              Flexible(
                child: Text(
                  itemsSelected.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppColors.accentColor,
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

  const _SearchCircleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return _NavigationSurface(
      width: 64,
      height: 64,
      onTap: onTap,
      semanticLabel: 'Buscar prospectos',
      child: const Center(
        child: Icon(
          Iconsax.search_normal_1_copy,
          color: AppColors.primaryColor,
          size: 30,
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
              gradient: AppColors.navigationGradient,
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
