import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_week_selector.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:callerapp_frontend/resources/styles/app_themes.dart';
import 'package:callerapp_frontend/services/business_clock.dart';

double _contrast(Color foreground, Color background) {
  final first = foreground.computeLuminance();
  final second = background.computeLuminance();
  final lighter = first > second ? first : second;
  final darker = first > second ? second : first;
  return (lighter + 0.05) / (darker + 0.05);
}

void _expectContrast(
  String label,
  Color foreground,
  Color background,
  double minimum,
) {
  expect(
    _contrast(foreground, background),
    greaterThanOrEqualTo(minimum),
    reason: '$label debería alcanzar $minimum:1',
  );
}

void main() {
  test('light palette preserves the original brand colors', () {
    expect(AppPalette.light.selectedFill, AppColors.primaryColor);
    expect(AppPalette.light.todayFill, AppColors.homeGreenToday);
    expect(AppPalette.light.fieldForeground, AppColors.primaryColor);
    expect(AppPalette.light.chipSelectedFill, AppColors.primaryColor);
    expect(AppPalette.light.navGradient, AppColors.navigationGradient);
    expect(AppPalette.light.navForeground, AppColors.primaryColor);
    expect(AppPalette.light.navSelectedFill, AppColors.primaryColor);
    expect(AppPalette.light.navSelectedForeground, AppColors.accentColor);
  });

  test('dark palette keeps text readable on surfaces and pastel cards', () {
    final dark = AppPalette.dark;
    const surface = Color(0xFF112521);
    const foreground = Color(0xFFE1F5EE);

    _expectContrast('foreground/surface', foreground, surface, 4.5);
    _expectContrast('accent/surface', dark.navForeground, surface, 4.5);

    for (final card in [
      AppColors.homeGreenCard,
      AppColors.homeYellowCard,
      AppColors.homeOrangeSection,
      AppColors.homeBlueSection,
      AppColors.homeRedSection,
    ]) {
      _expectContrast('cardInk/pastel', dark.cardInk, card, 4.5);
    }

    _expectContrast(
      'selected day',
      dark.selectedForeground,
      dark.selectedFill,
      4.5,
    );
    _expectContrast('today', dark.todayForeground, dark.todayFill, 4.5);
    _expectContrast('today border', dark.todayBorder, dark.todayFill, 3);
    _expectContrast('weekday', dark.navForeground, dark.calendarSurface, 4.5);
    _expectContrast('activity dot', dark.activityDot, dark.calendarSurface, 3);

    _expectContrast(
      'navigation icon',
      dark.navForeground,
      dark.navGradient.colors.last,
      4.5,
    );
    _expectContrast(
      'selected navigation',
      dark.navSelectedForeground,
      dark.navSelectedFill,
      4.5,
    );

    _expectContrast('field text', dark.fieldForeground, dark.fieldFill, 4.5);
    _expectContrast('field hint', dark.fieldHint, dark.fieldFill, 4.5);
    _expectContrast('chip', dark.chipForeground, dark.chipFill, 4.5);
    _expectContrast(
      'selected chip',
      dark.chipSelectedForeground,
      dark.chipSelectedFill,
      4.5,
    );
    _expectContrast(
      'secondary action',
      dark.secondaryActionForeground,
      dark.secondaryActionFill,
      4.5,
    );
    _expectContrast(
      'warm banner',
      dark.warmBannerForeground,
      dark.warmBannerFill,
      4.5,
    );
    _expectContrast('brand card', dark.onBrand, dark.brandFill, 4.5);
    _expectContrast('completed icon', dark.completedIcon, surface, 3);
    _expectContrast('pending icon', dark.pendingIcon, surface, 3);
  });

  testWidgets('dark theme exposes the semantic palette', (tester) async {
    late BuildContext context;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppThemes.build(Brightness.dark),
        home: Builder(
          builder: (value) {
            context = value;
            return const SizedBox();
          },
        ),
      ),
    );
    final theme = Theme.of(context);
    expect(theme.brightness, Brightness.dark);
    expect(theme.colorScheme.primary, const Color(0xFF91E5D6));
    expect(theme.colorScheme.onPrimary, const Color(0xFF06211D));
    expect(theme.colorScheme.surface, const Color(0xFF112521));
    final palette = AppPalette.of(context);
    expect(palette.selectedFill, AppPalette.dark.selectedFill);
    expect(palette.navGradient, AppPalette.dark.navGradient);
  });

  testWidgets('week selector shows selected and today readably in dark mode', (
    tester,
  ) async {
    final today = DateUtils.dateOnly(businessNow());
    final otherDay = today.weekday < DateTime.saturday
        ? today.add(const Duration(days: 1))
        : today.subtract(const Duration(days: 1));

    Widget app(DateTime selected) => MaterialApp(
      theme: AppThemes.build(Brightness.dark),
      home: Scaffold(
        body: AgendaWeekSelector(
          selectedDate: selected,
          activities: const [],
          onSelected: (_) {},
        ),
      ),
    );

    await tester.pumpWidget(app(today));
    final todayMaterial = tester.widget<Material>(
      find.byKey(const ValueKey('agenda-week-today')),
    );
    expect(todayMaterial.color, AppPalette.dark.selectedFill);
    final selectedLabel = tester.widget<Text>(find.text('${today.day}'));
    expect(selectedLabel.style!.color, AppPalette.dark.selectedForeground);

    await tester.pumpWidget(app(otherDay));
    final unselectedToday = tester.widget<Material>(
      find.byKey(const ValueKey('agenda-week-today')),
    );
    expect(unselectedToday.color, AppPalette.dark.todayFill);
    final shape = unselectedToday.shape! as RoundedRectangleBorder;
    expect(shape.side.color, AppPalette.dark.todayBorder);
    final todayLabel = tester.widget<Text>(find.text('${today.day}'));
    expect(todayLabel.style!.color, AppPalette.dark.todayForeground);
  });
}
