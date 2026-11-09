import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospect_detail_screen.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/call_session_controller.dart';
import 'package:callerapp_frontend/services/phone_call_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('detalle usa inmediatamente el teléfono recién guardado', (
    tester,
  ) async {
    final auth = AuthService(
      client: MockClient(
        (_) async => http.Response(
          '{"status":"success","token":"test","usuario":{"id":3},"desarrollo_activo":{"id":4}}',
          200,
        ),
      ),
    );
    await auth.login('agente', 'password');
    final service = _DetailProspectsService(auth: auth);
    final repository = ProspectsRepository(auth: auth, service: service);
    addTearDown(repository.dispose);
    final callSession = CallSessionController();
    addTearDown(callSession.dispose);
    Uri? launched;
    final phoneCallService = PhoneCallService(
      canLaunch: (_) async => true,
      launch: (uri) async {
        launched = uri;
        return true;
      },
    );
    final prospect = demoProspects[1].copyWith(
      id: 10,
      channelId: 9,
      statusId: 1,
      interestDevelopmentId: 4,
      interestDevelopment: 'Runa',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: ProspectDetailScreen(
          prospect: prospect,
          prospectsRepository: repository,
          phoneCallService: phoneCallService,
          callSession: callSession,
          showCallReminder: (_) async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.ensureVisible(find.widgetWithText(FilterChip, 'Prospecto'));
    await tester.tap(find.widgetWithText(FilterChip, 'Prospecto'));
    await tester.pumpAndSettle();
    const newPhone = '529981234567';
    final phoneField = find.byKey(const Key('prospect_phone_field'));
    await tester.ensureVisible(phoneField);
    await tester.enterText(phoneField, '+52 (998) 123-4567');
    final save = find.widgetWithText(FilledButton, 'GUARDAR').last;
    await tester.ensureVisible(save);
    await tester.tap(save);
    await tester.pumpAndSettle();

    await tester.tap(find.byTooltip('Datos de contacto'));
    await tester.pumpAndSettle();
    expect(find.text(newPhone), findsOneWidget);
    expect(find.text(prospect.phone), findsNothing);

    Navigator.of(tester.element(find.text(newPhone))).pop();
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'Llamar'));
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, 'MARCAR'));
    await tester.pumpAndSettle();

    expect(launched, Uri.parse('tel:$newPhone'));
    await callSession.cancel();
  });
}

class _DetailProspectsService extends ProspectsService {
  _DetailProspectsService({required super.auth});

  @override
  Future<List<Map<String, dynamic>>> availableDevelopments() async => const [
    {'id': 4, 'nombre': 'Runa'},
  ];

  @override
  Future<List<Map<String, dynamic>>> availableLots([
    int? developmentId,
  ]) async => const [];

  @override
  Future<void> update(
    int prospectId,
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async {}

  @override
  void dispose() {}
}
