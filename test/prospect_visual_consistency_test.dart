import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_filters.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_card.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_filters_sheet.dart';
import 'package:callerapp_frontend/resources/styles/picker_theme.dart';
import 'package:callerapp_frontend/services/agenda_service.dart';

void main() {
  test(
    'Agenda resolves the corresponding avatar and preserves it in copies',
    () {
      final activity = AgendaService.fromJson(
        {
          'id': 1,
          'tipo': 'seguimiento',
          'estado': 'pendiente',
          'programada_at': '2026-10-15T22:00:00Z',
          'prospecto_avatar_url': '/avatars/17.png',
        },
        now: DateTime(2026, 10, 14),
        baseUrl: 'https://example.com',
      );
      expect(activity.prospectAvatarUrl, 'https://example.com/avatars/17.png');
      expect(activity.copyWith().prospectAvatarUrl, activity.prospectAvatarUrl);
    },
  );
  for (final overdue in [true, false]) {
    testWidgets('Date and time tags use actual deadline: overdue=$overdue', (
      tester,
    ) async {
      final date = DateTime.now().add(Duration(days: overdue ? -1 : 1));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ProspectCard(
              prospect: ProspectRecord(
                id: 17,
                name: 'Ana',
                phone: '',
                email: '',
                status: 'Nuevo',
                temperature: 'Frío',
                avatarColor: Colors.teal,
                statusColor: Colors.blue,
                nextContact: date,
              ),
            ),
          ),
        ),
      );
      final redTags = tester
          .widgetList<Container>(find.byType(Container))
          .where((c) => c.color == const Color(0xFFFF9FA4));
      expect(redTags.length, overdue ? 2 : 0);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Only today time tag is overdue after its hour has passed', (
    tester,
  ) async {
    final now = DateTime.now();
    final earlierToday = DateTime(now.year, now.month, now.day);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ProspectCard(
            prospect: ProspectRecord(
              id: 18,
              name: 'Luis',
              phone: '',
              email: '',
              status: 'Nuevo',
              temperature: 'Tibio',
              avatarColor: Colors.teal,
              statusColor: Colors.blue,
              nextContact: earlierToday,
            ),
          ),
        ),
      ),
    );

    final redTags = tester
        .widgetList<Container>(find.byType(Container))
        .where((container) => container.color == const Color(0xFFFF9FA4));
    expect(redTags.length, 1);
    expect(tester.takeException(), isNull);
  });
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'Range header actions remain visible below system inset at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        tester.view.padding = const FakeViewPadding(top: 24);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetPadding);
        await tester.pumpWidget(
          MaterialApp(
            locale: const Locale('es', 'MX'),
            supportedLocales: const [Locale('es', 'MX')],
            localizationsDelegates: GlobalMaterialLocalizations.delegates,
            theme: ThemeData(datePickerTheme: appDatePickerTheme),
            home: Scaffold(
              body: ProspectFiltersSheet(
                initial: ProspectFilters(
                  range: DateTimeRange(
                    start: DateTime(2026, 10, 1),
                    end: DateTime(2026, 10, 2),
                  ),
                ),
                count: (_) => 0,
              ),
            ),
          ),
        );
        final range = find.widgetWithText(
          RadioListTile<String>,
          'Rango personalizado',
        );
        await tester.ensureVisible(range);
        await tester.tap(range);
        await tester.pumpAndSettle();
        final save = find.text('Guardar');
        expect(save, findsOneWidget);
        expect(tester.getRect(save).top, greaterThanOrEqualTo(24));
        expect(tester.getRect(save).right, lessThanOrEqualTo(width));
        await tester.tap(save);
        await tester.pumpAndSettle();
        expect(find.byType(DateRangePickerDialog), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
