import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:callerapp_frontend/presentation/models/agenda_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/prospect_history_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/agenda_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospects_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospect_detail_screen.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_activity_detail.dart';
import 'package:callerapp_frontend/presentation/widgets/agenda/agenda_activity_tile.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_comments_panel.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_card.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';

void main() {
  testWidgets(
    'Activity missing avatar loads the correct assigned prospect avatar',
    (tester) async {
      var lookups = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AgendaActivityDetail(
              activity: AgendaActivity(
                id: 9,
                prospectId: 17,
                type: 'tarea',
                title: 'Tarea',
                prospect: 'Ana',
                description: '',
                date: DateTime.now(),
                status: AgendaStatus.pending,
              ),
              loadProspects: () async {
                lookups++;
                return [
                  const ProspectRecord(
                    id: 17,
                    name: 'Ana',
                    phone: '',
                    email: '',
                    status: 'Nuevo',
                    temperature: 'Caliente',
                    avatarColor: Colors.teal,
                    statusColor: Colors.blue,
                    avatarUrl: 'https://example.com/static/avatars/Frame-7.png',
                  ),
                ];
              },
              onClose: () {},
              onMessage: () {},
              onCall: () {},
              onOpenProspect: () {},
              onEdit: () {},
              onComplete: () {},
              onReschedule: () {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final images = tester.widgetList<Image>(find.byType(Image));
      expect(
        images.where(
          (image) =>
              image.image is NetworkImage &&
              (image.image as NetworkImage).url ==
                  'https://example.com/static/avatars/Frame-7.png',
        ),
        hasLength(1),
      );
      expect(lookups, 1);
      expect(tester.takeException(), isNull);
    },
  );
  const prospect = ProspectRecord(
    id: 17,
    name: 'Ana real',
    phone: '',
    email: '',
    status: 'Nuevo',
    temperature: 'Caliente',
    avatarColor: Colors.teal,
    statusColor: Colors.orange,
  );
  AgendaActivity activity(String type, {DateTime? deleteUntil}) =>
      AgendaActivity(
        id: 9,
        prospectId: 17,
        type: type,
        title: type.toUpperCase(),
        prospect: prospect.name,
        description: 'Descripción real',
        date: DateTime.now(),
        status: AgendaStatus.pending,
        deleteUntil: deleteUntil,
      );
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'Follow-up shows history, attends prospect and expires delete at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        var attended = 0;
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: AgendaActivityDetail(
                activity: activity(
                  'seguimiento',
                  deleteUntil: DateTime.now().add(const Duration(seconds: 2)),
                ),
                onClose: () {},
                onMessage: () {},
                onCall: () {},
                onOpenProspect: () => attended++,
                onEdit: () {},
                onComplete: () => fail('Follow-up must open prospect'),
                onReschedule: () {},
                onDelete: () {},
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Eliminar'), findsOneWidget);
        await tester.tap(find.text('ATENDER ACTIVIDAD'));
        expect(attended, 1);
        await tester.pump(const Duration(seconds: 3));
        expect(find.text('Eliminar'), findsNothing);
        await tester.scrollUntilVisible(
          find.text('Historial de comentarios'),
          180,
          scrollable: find.byType(Scrollable).first,
        );
        expect(find.text('Ubicación'), findsNothing);
        expect(find.text('DESCRIPCIÓN'), findsOneWidget);
        expect(find.text('Descripción real'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
  for (final source in ['prospects', 'agenda']) {
    testWidgets('$source opens the actual prospect detail', (tester) async {
      final router = GoRouter(
        routes: [
          GoRoute(
            path: '/',
            builder: (_, _) => Scaffold(
              body: source == 'prospects'
                  ? ProspectsScreen(loadProspects: () async => [prospect])
                  : AgendaScreen(
                      loadActivities: () async => [activity('seguimiento')],
                      loadProspects: () async => [prospect],
                    ),
            ),
          ),
          GoRoute(
            path: '/prospectos/:phone',
            builder: (_, state) =>
                ProspectDetailScreen(prospect: state.extra! as ProspectRecord),
          ),
        ],
      );
      addTearDown(router.dispose);
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();
      if (source == 'prospects') {
        final card = find.byType(ProspectCard);
        await tester.scrollUntilVisible(
          card,
          180,
          scrollable: find.byType(Scrollable).first,
        );
        await tester.tap(card);
      } else {
        tester
            .widget<AgendaActivityTile>(find.byType(AgendaActivityTile))
            .onTap();
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Ver prospecto'));
      }
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<ProspectDetailScreen>(find.byType(ProspectDetailScreen))
            .prospect
            .id,
        17,
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Discovery'))
            .selected,
        isTrue,
      );
      expect(
        tester
            .widget<FilterChip>(find.widgetWithText(FilterChip, 'Seguimiento'))
            .selected,
        isTrue,
      );
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets(
    'History retries and displays real comments without invented results',
    (tester) async {
      var attempts = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ProspectCommentsPanel(
                prospectId: 17,
                loadComments: () async {
                  if (++attempts == 1)
                    throw const ProspectsException('Error de conexión');
                  return [
                    ProspectHistoryComment(
                      comment: 'Nota del contacto real',
                      createdAt: DateTime(2026, 10, 14, 10, 23),
                      medium: 'whatsapp',
                      results: const [],
                    ),
                  ];
                },
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Reintentar'));
      await tester.pumpAndSettle();
      expect(find.text('Nota del contacto real'), findsOneWidget);
      expect(find.text('Contestó'), findsNothing);
      expect(find.text('No Contestó'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
