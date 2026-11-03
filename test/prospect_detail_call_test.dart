import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospect_detail_screen.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/call_in_progress_bar.dart';
import 'package:callerapp_frontend/services/call_log_service.dart';
import 'package:callerapp_frontend/services/call_session_controller.dart';
import 'package:callerapp_frontend/services/phone_call_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeCallLogService extends CallLogService {
  _FakeCallLogService({this.active});

  bool? active;

  @override
  Future<CallLogMatch?> latestFor(String phone, DateTime startedAt) async =>
      null;

  @override
  Future<bool?> isCallActive() async => active;
}

void main() {
  testWidgets('impide salir después de una llamada sin guardar seguimiento', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ProspectDetailScreen(
          prospect: demoProspects[1],
          callStarted: true,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();

    expect(find.text('Seguimiento obligatorio'), findsOneWidget);
    expect(find.textContaining('debes completar y guardar'), findsOneWidget);
    expect(find.text('LLENAR SEGUIMIENTO'), findsOneWidget);
  });

  testWidgets('volver del marcador sin llamar descarta la sesión', (
    tester,
  ) async {
    final log = _FakeCallLogService(active: false);
    final controller = CallSessionController(callLog: log);
    addTearDown(controller.dispose);
    final prospect = demoProspects[1];
    ProspectRecord? reminderProspect;

    await tester.pumpWidget(
      MaterialApp(
        home: ProspectDetailScreen(
          prospect: prospect,
          callSession: controller,
          phoneCallService: PhoneCallService(
            canLaunch: (_) async => true,
            launch: (_) async => true,
          ),
          showCallReminder: (prospect) async => reminderProspect = prospect,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.widgetWithText(FilledButton, 'Llamar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'MARCAR'));
    await tester.pumpAndSettle();

    expect(controller.activeCall, isNotNull);
    expect(reminderProspect, prospect);
    expect(find.byType(CallInProgressBar), findsNothing);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(controller.activeCall, isNull);
    expect(find.byType(CallInProgressBar), findsNothing);
    expect(find.text('REGISTRAR LLAMADA'), findsNothing);
  });
}
