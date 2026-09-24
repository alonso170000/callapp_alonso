import 'package:flutter/material.dart';
import 'package:callerapp_frontend/presentation/screens/screens.dart';

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
  static const Duration _animationDuration = Duration(milliseconds: 300);
  static const Curve _animationCurve = Curves.easeOutCubic;

  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  int selectedIndex = 0;
  bool _isSearchOpen = false;

  final List<_NavigationItem> itemsNoSelected = const [
    _NavigationItem(icon: Icons.home_outlined, label: 'Inicio'),
    _NavigationItem(icon: Icons.person_add_alt_1_outlined, label: 'Contactos'),
    _NavigationItem(icon: Icons.calendar_today_outlined, label: 'Agenda'),
    _NavigationItem(icon: Icons.account_circle_outlined, label: 'Perfil'),
  ];

  final List<_NavigationItem> itemsSelected = const [
    _NavigationItem(icon: Icons.home_rounded, label: 'Inicio'),
    _NavigationItem(icon: Icons.person_add_alt_1_rounded, label: 'Contactos'),
    _NavigationItem(icon: Icons.calendar_month_rounded, label: 'Agenda'),
    _NavigationItem(icon: Icons.account_circle_rounded, label: 'Perfil'),
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
      children: [
        Expanded(
          child: LiquidGlass(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              children: List.generate(itemsSelected.length, (index) {
                final itemsSelec = itemsSelected[index];
                final itemsNoSelec = itemsNoSelected[index];
                final isSelected = selectedIndex == index;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () {
                      setState(() {
                        selectedIndex = index;
                      });
                      widget.onDestinationSelected?.call(index);
                    },
                    child: AnimatedOpacity(
                      duration: _animationDuration,
                      opacity: 1,
                      child: _NavigationOption(
                        itemsSelected: itemsSelec,
                        itemsNoSelected: itemsNoSelec,
                        isSelected: isSelected,
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),
        const SizedBox(width: 14),
        _SearchCircleButton(onTap: _openSearch),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Row(
      key: const ValueKey('search-navigation-bar'),
      children: [
        LiquidGlass(
          style: LiquidGlassStyle.button,
          width: 64,
          height: 64,
          onTap: _closeSearch,
          semanticLabel: 'Cerrar búsqueda',
          child: Center(
            child: Icon(
              Icons.home_outlined,
              color: AppColors.whiteColor,
              size: 28,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: LiquidGlass(
            height: 64,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Center(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                autocorrect: false,
                textInputAction: TextInputAction.search,
                cursorColor: AppColors.whiteColor,
                style: const TextStyle(
                  color: AppColors.whiteColor,
                  fontSize: 16,
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  isDense: true,
                  hintText: 'Buscar prospecto...',
                  hintStyle: const TextStyle(
                    color: AppColors.textSecondaryColor,
                    fontSize: 15,
                  ),
                  prefixIcon: const Icon(
                    Icons.search_rounded,
                    color: AppColors.textSecondaryColor,
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
                            color: AppColors.textSecondaryColor,
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
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          isSelected ? itemsSelected.icon : itemsNoSelected.icon,
          color: isSelected
              ? AppColors.whiteColor
              : AppColors.textSecondaryColor,
          size: 26,
        ),
        const SizedBox(height: 4),
        Text(
          itemsNoSelected.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: isSelected
                ? AppColors.whiteColor
                : AppColors.textSecondaryColor,
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }
}

class _SearchCircleButton extends StatelessWidget {
  final VoidCallback onTap;

  const _SearchCircleButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return LiquidGlass(
      style: LiquidGlassStyle.button,
      width: 64,
      height: 64,
      onTap: onTap,
      semanticLabel: 'Buscar películas',
      child: const Center(
        child: Icon(
          Icons.search_rounded,
          color: AppColors.whiteColor,
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
