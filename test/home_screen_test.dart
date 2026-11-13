import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';
import 'package:callerapp_frontend/presentation/widgets/home/prospect_section.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/services/notification_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('Inicio scrolls without overflow at $width px', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            loadActivities: () async => [],
            loadProspects: () async => [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);

      await tester.drag(
        find.byType(CustomScrollView).first,
        const Offset(0, -500),
      );
      await tester.pumpAndSettle();
      expect(find.text('Seguimientos atrasados'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Inicio retries a failed load and refreshes after returning', (
    tester,
  ) async {
    var requests = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: HomeScreen(
          loadActivities: () async => [],
          loadProspects: () async {
            if (++requests == 1) throw Exception('offline');
            return [
              ProspectRecord(
                id: 77,
                name: 'Prospecto real',
                phone: '9981234567',
                email: '',
                status: 'Nuevo',
                assignedAt: DateTime.now(),
                temperature: 'Caliente',
                avatarColor: Colors.teal,
                statusColor: Colors.orange,
              ),
            ];
          },
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Reintentar'), findsWidgets);
    await tester.tap(find.text('Reintentar').first);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Prospectos nuevos'),
      180,
      scrollable: find.byType(Scrollable).first,
    );
    final sections = tester
        .widgetList<ProspectSection>(find.byType(ProspectSection))
        .toList();
    final newProspects = sections.firstWhere(
      (section) => section.title == 'Prospectos nuevos',
    );
    expect(newProspects.prospects.single.name, 'Prospecto real');
    newProspects.onOpen!();
    await tester.pumpAndSettle();
    // Navigation back to Inicio reloads server data.
    final before = requests;
    await tester.tap(find.bySemanticsLabel('Inicio').last);
    await tester.pumpAndSettle();
    expect(requests, greaterThan(before));
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'una notificación abre como ver seguimiento si la actividad ya se completó',
    (tester) async {
      final now = businessNow();
      final pending = AgendaActivity(
        id: 91,
        prospectId: 12,
        type: 'seguimiento',
        medium: 'llamada',
        title: 'SEGUIMIENTO',
        prospect: 'Alan Dorantes',
        description: 'Llamar',
        date: now.add(const Duration(minutes: 12)),
        status: AgendaStatus.pending,
        reminderMinutes: 15,
      );
      final completed = pending.copyWith(status: AgendaStatus.completed);
      await NotificationService.instance.syncActivities([pending]);
      addTearDown(NotificationService.instance.endSession);

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            loadActivities: () async => [completed],
            loadProspects: () async => [],
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Notificaciones').first);
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('notification-91')));
      await tester.pumpAndSettle();

      expect(find.text('VER SEGUIMIENTO'), findsOneWidget);
      expect(find.text('ATENDER ACTIVIDAD'), findsNothing);
      expect(find.text('COMPLETAR ACTIVIDAD'), findsNothing);
    },
  );
}
