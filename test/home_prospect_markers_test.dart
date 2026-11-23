import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/home_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';
import 'package:callerapp_frontend/presentation/widgets/home/prospect_section.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('Prospectos del día muestra orden y marcadores a $width px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);

      final today = DateUtils.dateOnly(businessNow());
      ProspectRecord prospect(int id) => ProspectRecord(
        id: id,
        name: 'Persona $id',
        phone: '998000000$id',
        email: '',
        status: 'Seguimiento',
        temperature: 'Tibio',
        avatarColor: AppColors.homeGreenCard,
        statusColor: AppColors.homeOrangeSection,
      );
      AgendaActivity activity(
        int id,
        int prospectId,
        int hour,
        AgendaStatus status,
      ) => AgendaActivity(
        id: id,
        prospectId: prospectId,
        title: 'Actividad $id',
        prospect: 'Persona $prospectId',
        description: '',
        date: today.add(Duration(hours: hour)),
        status: status,
      );
      final prospects = [prospect(1), prospect(2), prospect(3), prospect(4)];
      final activities = [
        activity(1, 1, 9, AgendaStatus.overdue),
        activity(2, 3, 10, AgendaStatus.completed),
        activity(3, 2, 11, AgendaStatus.pending),
        activity(4, 2, 8, AgendaStatus.completed),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: HomeScreen(
            loadActivities: () async => activities,
            loadProspects: () async => prospects,
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Prospectos del día'),
        180,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      final section = tester
          .widgetList<ProspectSection>(find.byType(ProspectSection))
          .firstWhere((value) => value.title == 'Prospectos del día');
      expect(section.prospects.map((item) => item.name), [
        'Persona 1',
        'Persona 2',
        'Persona 3',
      ]);
      expect(section.prospects.map((item) => item.marker), [
        ProspectActivityMarker.overdue,
        ProspectActivityMarker.pending,
        null,
      ]);

      void expectMarker(String name, Color color, String semantics) {
        final marker = find.byKey(Key('prospect-activity-marker-$name'));
        expect(marker, findsOneWidget);
        final semanticsWidget = tester.widget<Semantics>(
          find.ancestor(of: marker, matching: find.byType(Semantics)).first,
        );
        expect(semanticsWidget.properties.label, semantics);
        final inner = tester.widget<Container>(
          find.descendant(of: marker, matching: find.byType(Container)),
        );
        expect((inner.decoration! as BoxDecoration).color, color);
      }

      expectMarker(
        'Persona 1',
        AppColors.homeActivityOverdue,
        'Actividad atrasada',
      );
      expectMarker(
        'Persona 2',
        AppColors.homeActivityPending,
        'Actividad pendiente',
      );
      expect(
        find.byKey(const Key('prospect-activity-marker-Persona 3')),
        findsNothing,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
