import 'package:callerapp_frontend/presentation/models/prospect_filters.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_filters_sheet.dart';
import 'package:callerapp_frontend/resources/styles/app_themes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 16, 12);

  Widget subject({
    required ProspectFilters initial,
    int Function(ProspectFilters)? count,
    Brightness brightness = Brightness.light,
  }) => MaterialApp(
    theme: AppThemes.build(brightness),
    home: Scaffold(
      body: ProspectFiltersSheet(
        initial: initial,
        count:
            count ??
            (filter) =>
                demoProspects.where((item) => filter.matches(item, now)).length,
        now: () => now,
      ),
    ),
  );

  testWidgets('Cualquiera clears the group and updates the counter', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(
        initial: ProspectFilters(nextContact: 'Hoy'),
        count: (filter) => filter.nextContact == null ? 6 : 2,
      ),
    );
    expect(find.text('2 resultados'), findsOneWidget);
    await tester.tap(find.text('Cualquiera').first);
    await tester.pump();
    expect(find.text('6 resultados'), findsOneWidget);
  });

  testWidgets('Todos shows all six demo prospects', (tester) async {
    await tester.pumpWidget(subject(initial: ProspectFilters.forSeller()));
    await tester.tap(find.widgetWithText(ChoiceChip, 'Todos'));
    await tester.pump();
    expect(find.text('VER 6 RESULTADOS'), findsOneWidget);
  });

  testWidgets('zero results disables the CTA and explains how to continue', (
    tester,
  ) async {
    await tester.pumpWidget(
      subject(initial: ProspectFilters.all(), count: (_) => 0),
    );
    expect(find.text('SIN RESULTADOS'), findsOneWidget);
    expect(
      find.text('Ajusta la selección para ver prospectos'),
      findsOneWidget,
    );
    expect(
      tester
          .widget<FilledButton>(
            find.ancestor(
              of: find.text('SIN RESULTADOS'),
              matching: find.byType(FilledButton),
            ),
          )
          .onPressed,
      isNull,
    );
  });

  testWidgets('Restablecer returns to the seller preset', (tester) async {
    await tester.pumpWidget(
      subject(initial: ProspectFilters.all(), count: (_) => 6),
    );
    await tester.tap(find.text('RESTABLECER'));
    await tester.pump();
    expect(
      tester
          .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Por atender'))
          .selected,
      isTrue,
    );
    for (final value in ['Caliente', 'Tibio']) {
      await tester.ensureVisible(find.widgetWithText(CheckboxListTile, value));
      expect(
        tester
            .widget<CheckboxListTile>(
              find.widgetWithText(CheckboxListTile, value),
            )
            .value,
        isTrue,
      );
    }
  });

  testWidgets('renders in dark mode at 320x640 without overflow', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(320, 640);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      subject(
        initial: ProspectFilters.forSeller(),
        brightness: Brightness.dark,
      ),
    );
    await tester.pump();
    expect(tester.takeException(), isNull);
  });

  testWidgets('radio buttons and checkboxes expose Spanish semantics', (
    tester,
  ) async {
    await tester.pumpWidget(subject(initial: ProspectFilters.forSeller()));
    Finder semanticsWith(String label) => find.byWidgetPredicate(
      (widget) => widget is Semantics && widget.properties.label == label,
    );
    expect(semanticsWith('Cualquiera'), findsWidgets);
    expect(semanticsWith('Caliente'), findsWidgets);
  });
}
