import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:callerapp_frontend/presentation/widgets/home/home_header.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/services/notification_service.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'Notification inbox shows elapsed alert and opens it at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        final now = businessNow();
        final activity = AgendaActivity(
          id: 91,
          prospectId: 12,
          type: 'seguimiento',
          medium: 'llamada',
          title: 'SEGUIMIENTO',
          prospect: 'Alan Dorantes',
          description: 'Llamar',
          date: now
              .subtract(const Duration(minutes: 3))
              .add(const Duration(minutes: 15)),
          status: AgendaStatus.pending,
          reminderMinutes: 15,
        );
        await NotificationService.instance.syncActivities([activity]);
        addTearDown(NotificationService.instance.clearActivityReminders);
        AgendaActivity? opened;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SafeArea(
                child: HomeHeader(
                  userName: 'Ana',
                  onNotificationActivity: (activity) => opened = activity,
                ),
              ),
            ),
          ),
        );
        expect(
          find.byKey(const ValueKey('notification-unread-badge')),
          findsOneWidget,
        );
        expect(find.text('1'), findsOneWidget);
        await tester.tap(find.byTooltip('Notificaciones'));
        await tester.pumpAndSettle();
        expect(find.text('NOTIFICACIONES'), findsOneWidget);
        expect(find.text('SEGUIMIENTO'), findsOneWidget);
        expect(find.text('ALAN DORANTES'), findsOneWidget);
        expect(find.text('3m'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('new-notification-91')),
          findsOneWidget,
        );
        expect(tester.takeException(), isNull);
        await tester.tap(find.byKey(const ValueKey('notification-91')));
        await tester.pumpAndSettle();
        expect(find.text('NOTIFICACIONES'), findsNothing);
        expect(opened?.id, 91);
        expect(NotificationService.instance.reminders.single.isRead, isTrue);
      },
    );
  }

  testWidgets('Filters, sections, mark all and swipe delete notifications', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    final today = DateUtils.dateOnly(businessNow());
    AgendaActivity activity(int id, DateTime reminderAt) => AgendaActivity(
      id: id,
      type: 'tarea',
      title: 'TAREA $id',
      prospect: 'Actividad personal',
      description: 'Pendiente',
      date: reminderAt.add(const Duration(minutes: 15)),
      status: AgendaStatus.pending,
      reminderMinutes: 15,
    );
    await NotificationService.instance.syncActivities([
      activity(1, businessNow().subtract(const Duration(minutes: 5))),
      activity(2, today.subtract(const Duration(days: 1))),
      activity(3, today.subtract(const Duration(days: 2))),
    ]);
    await NotificationService.instance.markRead(2);
    addTearDown(NotificationService.instance.clearActivityReminders);

    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SafeArea(child: HomeHeader(userName: 'Ana')),
        ),
      ),
    );
    await tester.tap(find.byTooltip('Notificaciones'));
    await tester.pumpAndSettle();

    expect(find.text('Todas'), findsOneWidget);
    expect(find.text('Pendientes'), findsOneWidget);
    expect(find.text('Leídas'), findsOneWidget);
    expect(find.text('HOY'), findsOneWidget);
    expect(find.text('AYER'), findsOneWidget);
    expect(
      find.text(_exactSection(today.subtract(const Duration(days: 2)))),
      findsOneWidget,
    );

    await tester.ensureVisible(find.text('Leídas'));
    await tester.tap(find.text('Leídas'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-2')), findsOneWidget);
    expect(find.byKey(const ValueKey('notification-1')), findsNothing);

    await tester.ensureVisible(find.text('Todas'));
    await tester.tap(find.text('Todas'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Marcar todas como leídas'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('new-notification-1')), findsNothing);

    final dismissible = find.byKey(const ValueKey('dismiss-notification-3'));
    await tester.ensureVisible(dismissible);
    await tester.drag(dismissible, const Offset(-500, 0));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('notification-3')), findsNothing);
    expect(NotificationService.instance.reminders, hasLength(2));
    expect(tester.takeException(), isNull);
  });
}

String _exactSection(DateTime date) {
  const months = [
    'ENERO',
    'FEBRERO',
    'MARZO',
    'ABRIL',
    'MAYO',
    'JUNIO',
    'JULIO',
    'AGOSTO',
    'SEPTIEMBRE',
    'OCTUBRE',
    'NOVIEMBRE',
    'DICIEMBRE',
  ];
  return '${date.day} DE ${months[date.month - 1]} DE ${date.year}';
}
