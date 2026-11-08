import 'dart:math' as math;

import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:flutter/material.dart';
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
  final itemsNoSelected = const [
    _NavigationItem(icon: Iconsax.home_2_copy, label: 'Inicio'),
    _NavigationItem(icon: Iconsax.profile_2user_copy, label: 'Prospectos'),
    _NavigationItem(icon: Iconsax.calendar_2_copy, label: 'Agenda'),
    _NavigationItem(icon: Iconsax.profile_circle_copy, label: 'Perfil'),
  ];
  final itemsSelected = const [
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
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final addAction = _addActionForSelection();
      final metrics = _NavMetrics.resolve(
        context: context,
        maxWidth: constraints.maxWidth,
        usesAddButtonBudget:
            widget.onAddProspect != null || widget.onAddAgenda != null,
        showsAddButton: addAction != null,
      );
      return Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _NavMetrics.outerPadding,
        ),
        child: Center(
          child: SizedBox(
            width: metrics.availableWidth,
            child: _buildBar(metrics, addAction),
          ),
        ),
      );
    },
  );

  VoidCallback? _addActionForSelection() => selectedIndex == 1
      ? widget.onAddProspect
      : selectedIndex == 2
      ? widget.onAddAgenda
      : null;

  Widget _buildBar(_NavMetrics metrics, VoidCallback? addAction) {
    final addLabel = selectedIndex == 1
        ? 'Agregar prospecto'
        : 'Agendar nueva actividad';
    return Row(
      key: const ValueKey('normal-navigation-bar'),
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (metrics.reservesAddButton) ...[
          _AddAgendaButton(
            onTap: addAction!,
            metrics: metrics,
            label: addLabel,
          ),
          SizedBox(width: metrics.gap),
        ],
        _NavigationSurface(
          height: metrics.barHeight,
          width: metrics.surfaceWidth,
          radius: metrics.radius,
          padding: EdgeInsets.symmetric(horizontal: metrics.surfacePadding),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            spacing: metrics.spacing,
            children: List.generate(itemsSelected.length, (index) {
              final isSelected = selectedIndex == index;
              final option = GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  setState(() => selectedIndex = index);
                  widget.onDestinationSelected?.call(index);
                },
                child: _NavigationOption(
                  itemsSelected: itemsSelected[index],
                  itemsNoSelected: itemsNoSelected[index],
                  isSelected: isSelected,
                  metrics: metrics,
                ),
              );
              return isSelected && metrics.showLabel
                  ? Expanded(child: option)
                  : SizedBox(
                      width: isSelected
                          ? metrics.pillWidth
                          : metrics.inactiveSlot,
                      child: option,
                    );
            }),
          ),
        ),
        SizedBox(width: metrics.gap),
        _SearchCircleButton(onTap: widget.onSearchTap, metrics: metrics),
      ],
    );
  }
}

class _NavMetrics {
  static const outerPadding = 8.0;
  static const maxAvailableWidth = 480.0;
  static const minimumCircle = 44.0;
  static const maximumCircle = 64.0;
  static const noAddMinimumCircle = 56.0;
  static const gapValue = 8.0;
  static const surfacePaddingValue = 8.0;
  static const spacingValue = 4.0;
  static const inactiveSlotValue = 32.0;
  static const pillMargin = 2.0;
  static const pillPadding = 6.0;
  static const pillIconSize = 24.0;
  static const labelGap = 3.0;
  static const pillVerticalInset = 8.0;
  static const iconOnlyPillWidth = 48.0;
  static const searchIconRatio = 30 / 64;
  static const addIconRatio = 40 / 64;
  static const fontSizeTiers = [16.0, 14.0, 13.0];

  final double availableWidth,
      surfaceWidth,
      circleSize,
      barHeight,
      pillHeight,
      pillWidth,
      radius;
  final double iconSize,
      searchIconSize,
      addIconSize,
      fontSize,
      gap,
      spacing,
      surfacePadding,
      inactiveSlot;
  final bool showLabel, reservesAddButton;

  const _NavMetrics({
    required this.availableWidth,
    required this.surfaceWidth,
    required this.circleSize,
    required this.barHeight,
    required this.pillHeight,
    required this.pillWidth,
    required this.radius,
    required this.iconSize,
    required this.searchIconSize,
    required this.addIconSize,
    required this.fontSize,
    required this.gap,
    required this.spacing,
    required this.surfacePadding,
    required this.inactiveSlot,
    required this.showLabel,
    required this.reservesAddButton,
  });

  factory _NavMetrics.resolve({
    required BuildContext context,
    required double maxWidth,
    required bool usesAddButtonBudget,
    required bool showsAddButton,
  }) {
    final boundedWidth = maxWidth.isFinite
        ? maxWidth
        : MediaQuery.sizeOf(context).width;
    final available = math.min(
      maxAvailableWidth,
      math.max(0.0, boundedWidth - 2 * outerPadding),
    );
    final scaler = MediaQuery.textScalerOf(context)
        .clamp(minScaleFactor: 0, maxScaleFactor: 1.2);
    var selectedFontSize = fontSizeTiers.last;
    var selectedPillWidth = iconOnlyPillWidth;
    var selectedCircle = minimumCircle;
    var showLabel = false;

    for (final fontSize in fontSizeTiers) {
      final textWidth = _measureLongestLabel(fontSize, scaler);
      final pill =
          2 * pillMargin +
          2 * pillPadding +
          pillIconSize +
          labelGap +
          textWidth;
      final requiredSurface =
          2 * surfacePaddingValue +
          3 * spacingValue +
          3 * inactiveSlotValue +
          pill;
      final budgetCircle = usesAddButtonBudget
          ? (available - requiredSurface - 2 * gapValue) / 2
          : available - requiredSurface - gapValue;
      if (budgetCircle >= minimumCircle) {
        selectedFontSize = fontSize;
        selectedPillWidth = pill;
        final layoutCircle = usesAddButtonBudget
            ? (available - requiredSurface - 2 * gapValue) / 2
            : available - requiredSurface - gapValue;
        selectedCircle = usesAddButtonBudget
            ? layoutCircle.clamp(minimumCircle, maximumCircle)
            : layoutCircle.clamp(noAddMinimumCircle, maximumCircle);
        showLabel = true;
        break;
      }
    }
    if (!showLabel) {
      const iconOnlySurface =
          2 * surfacePaddingValue +
          3 * spacingValue +
          3 * inactiveSlotValue +
          iconOnlyPillWidth;
      final circle = usesAddButtonBudget
          ? (available - iconOnlySurface - 2 * gapValue) / 2
          : available - iconOnlySurface - gapValue;
      selectedCircle = circle.clamp(minimumCircle, maximumCircle);
    }
    final surfaceWidth = math.max(
      0.0,
      available -
          selectedCircle * (usesAddButtonBudget ? 2 : 1) -
          gapValue * (usesAddButtonBudget ? 2 : 1),
    );
    final barHeight = selectedCircle;
    final iconScale = math.min(1.0, (barHeight - pillVerticalInset) / 42);
    return _NavMetrics(
      availableWidth: available,
      surfaceWidth: surfaceWidth,
      circleSize: selectedCircle,
      barHeight: barHeight,
      pillHeight: barHeight - pillVerticalInset,
      pillWidth: selectedPillWidth,
      radius: barHeight / 2,
      iconSize: pillIconSize * iconScale,
      searchIconSize: barHeight * searchIconRatio,
      addIconSize: barHeight * addIconRatio,
      fontSize: selectedFontSize,
      gap: gapValue,
      spacing: spacingValue,
      surfacePadding: surfacePaddingValue,
      inactiveSlot: inactiveSlotValue,
      showLabel: showLabel,
      reservesAddButton: showsAddButton,
    );
  }

  static double _measureLongestLabel(double fontSize, TextScaler scaler) {
    final painter = TextPainter(
      text: TextSpan(
        text: 'Prospectos',
        style: TextStyle(
          fontFamily: 'SulphurPoint',
          fontSize: fontSize,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
      maxLines: 1,
      textDirection: TextDirection.ltr,
      textScaler: scaler,
    )..layout();
    return painter.width.ceilToDouble() + 4;
  }
}

class _NavigationOption extends StatelessWidget {
  final _NavigationItem itemsNoSelected, itemsSelected;
  final bool isSelected;
  final _NavMetrics metrics;
  const _NavigationOption({
    required this.itemsNoSelected,
    required this.itemsSelected,
    required this.isSelected,
    required this.metrics,
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
        height: metrics.pillHeight,
        margin: const EdgeInsets.symmetric(horizontal: _NavMetrics.pillMargin),
        padding: EdgeInsets.symmetric(
          horizontal: isSelected ? _NavMetrics.pillPadding : 0,
        ),
        decoration: BoxDecoration(
          color: isSelected ? palette.navSelectedFill : Colors.transparent,
          borderRadius: BorderRadius.circular(metrics.pillHeight / 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSelected ? itemsSelected.icon : itemsNoSelected.icon,
              color: isSelected
                  ? palette.navSelectedForeground
                  : palette.navForeground,
              size: metrics.iconSize,
            ),
            if (isSelected && metrics.showLabel) ...[
              const SizedBox(width: _NavMetrics.labelGap),
              Flexible(
                child: Text(
                  itemsSelected.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: palette.navSelectedForeground,
                    fontFamily: 'SulphurPoint',
                    fontSize: metrics.fontSize,
                    height: 1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SearchCircleButton extends StatelessWidget {
  final VoidCallback? onTap;
  final _NavMetrics metrics;
  const _SearchCircleButton({required this.onTap, required this.metrics});
  @override
  Widget build(BuildContext context) => _NavigationSurface(
    width: metrics.circleSize,
    height: metrics.barHeight,
    radius: metrics.radius,
    onTap: onTap,
    semanticLabel: 'Buscar prospectos',
    child: Center(
      child: Icon(
        Iconsax.search_normal_1_copy,
        color: AppPalette.of(context).navForeground,
        size: metrics.searchIconSize,
      ),
    ),
  );
}

class _AddAgendaButton extends StatelessWidget {
  final VoidCallback? onTap;
  final _NavMetrics metrics;
  final String label;
  const _AddAgendaButton({
    required this.onTap,
    required this.metrics,
    required this.label,
  });
  @override
  Widget build(BuildContext context) => _NavigationSurface(
    width: metrics.circleSize,
    height: metrics.barHeight,
    radius: metrics.radius,
    onTap: onTap,
    semanticLabel: label,
    child: Center(
      child: Icon(
        Iconsax.add_copy,
        color: AppPalette.of(context).navForeground,
        size: metrics.addIconSize,
      ),
    ),
  );
}

class _NavigationItem {
  final IconData icon;
  final String label;
  const _NavigationItem({required this.icon, required this.label});
}

class _NavigationSurface extends StatelessWidget {
  final Widget child;
  final double width, height, radius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final String? semanticLabel;
  const _NavigationSurface({
    required this.child,
    required this.width,
    required this.height,
    required this.radius,
    this.padding = EdgeInsets.zero,
    this.onTap,
    this.semanticLabel,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = BorderRadius.circular(radius);
    return Semantics(
      button: onTap != null,
      label: semanticLabel,
      child: SizedBox(
        width: width,
        height: height,
        child: Material(
          color: Colors.transparent,
          borderRadius: borderRadius,
          clipBehavior: Clip.antiAlias,
          child: Ink(
            decoration: BoxDecoration(
              gradient: AppPalette.of(context).navGradient,
              borderRadius: borderRadius,
            ),
            child: InkWell(
              onTap: onTap,
              borderRadius: borderRadius,
              child: Padding(padding: padding, child: child),
            ),
          ),
        ),
      ),
    );
  }
}
