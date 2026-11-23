import 'package:callerapp_frontend/presentation/models/call_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_call_history_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ProspectCallRecord call(String outcome, int id) => ProspectCallRecord(
    id: id,
    startedAt: DateTime(2026, 9, 15, 10),
    durationSeconds: 10,
    durationEstimated: false,
    outcome: outcome,
    phone: '9980000000',
    audioState: 'pendiente',
  );

  Widget app(Widget child) => MaterialApp(
    home: Scaffold(body: SingleChildScrollView(child: child)),
  );

  for (final width in [320.0, 390.0]) {
    testWidgets('muestra resumen de llamadas sin overflow a $width px', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      await tester.pumpWidget(
        app(
          ProspectCallHistoryPanel(
            loading: false,
            calls: [
              call(ProspectCallOutcome.answered.value, 1),
              call(ProspectCallOutcome.answered.value, 2),
              call(ProspectCallOutcome.answered.value, 3),
              call(ProspectCallOutcome.unanswered.value, 4),
            ],
          ),
        ),
      );

      expect(find.text('Efectividad de contactos'), findsOneWidget);
      expect(find.text('Resumen de llamadas'), findsOneWidget);
      expect(find.text('Contestó'), findsOneWidget);
      expect(find.text('No contestó'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(find.text('1'), findsOneWidget);
      expect(find.text('75%'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
      final answeredBar = find.byKey(
        const ValueKey('call-summary-answered-bar'),
      );
      final unansweredBar = find.byKey(
        const ValueKey('call-summary-unanswered-bar'),
      );
      expect(tester.getSize(answeredBar).height, 12);
      expect(tester.getSize(unansweredBar).height, 12);
      expect(
        tester.getSize(answeredBar).width / tester.getSize(unansweredBar).width,
        closeTo(3, 0.01),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('muestra el estado vacío sin tarjeta', (tester) async {
    await tester.pumpWidget(
      app(const ProspectCallHistoryPanel(calls: [], loading: false)),
    );

    expect(find.text('Aún no se han registrado llamadas.'), findsOneWidget);
    expect(find.text('Resumen de llamadas'), findsNothing);
  });

  testWidgets('muestra error y permite reintentar', (tester) async {
    var retries = 0;
    await tester.pumpWidget(
      app(
        ProspectCallHistoryPanel(
          calls: const [],
          loading: false,
          error: 'No se pudo cargar.',
          onRetry: () => retries++,
        ),
      ),
    );

    expect(find.text('No se pudo cargar.'), findsOneWidget);
    await tester.tap(find.text('Reintentar'));
    expect(retries, 1);
  });

  testWidgets('muestra progreso mientras carga', (tester) async {
    await tester.pumpWidget(
      app(const ProspectCallHistoryPanel(calls: [], loading: true)),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });
}
