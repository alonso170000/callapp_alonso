import 'package:callerapp_frontend/presentation/models/sync_models.dart';
import 'package:callerapp_frontend/presentation/widgets/sync_conflicts_sheet.dart';
import 'package:callerapp_frontend/presentation/widgets/sync_pending_sheet.dart';
import 'package:callerapp_frontend/presentation/widgets/sync_status_indicator.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets('muestra pendientes y permite sincronizar a $width', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      var syncs = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(
              pendingCount: 2,
              conflictCount: 0,
              syncing: false,
              onSync: () => syncs++,
              onConflicts: () {},
              onPending: () {},
            ),
          ),
        ),
      );

      expect(find.text('2 cambios pendientes'), findsOneWidget);
      await tester.tap(find.text('SINCRONIZAR AHORA'));
      expect(syncs, 1);
      expect(tester.takeException(), isNull);
    });

    testWidgets('muestra conflictos sin overflow a $width', (tester) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      var reviews = 0;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SyncStatusIndicator(
              pendingCount: 0,
              conflictCount: 1,
              syncing: false,
              onSync: () {},
              onConflicts: () => reviews++,
              onPending: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.text('REVISAR'));
      expect(reviews, 1);
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('el panel permite usar la versión del servidor', (tester) async {
    var discarded = 0;
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => SyncConflictsSheet(
                  conflicts: const [
                    SyncConflictViewData(
                      id: 7,
                      title: 'ELIMINAR ACTIVIDAD',
                      message: 'La ventana para eliminar terminó.',
                      attemptCount: 2,
                    ),
                  ],
                  onRetry: (_) async => retried++,
                  onDiscard: (_) async => discarded++,
                ),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('USAR VERSIÓN DEL SERVIDOR'));
    await tester.pumpAndSettle();

    expect(discarded, 1);
    expect(find.byType(SyncConflictsSheet), findsNothing);

    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();
    expect(retried, 1);
    expect(find.byType(SyncConflictsSheet), findsNothing);
  });

  testWidgets('VER DETALLE abre los cambios pendientes con su motivo', (
    tester,
  ) async {
    var retried = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => SyncStatusIndicator(
              pendingCount: 1,
              conflictCount: 0,
              syncing: false,
              onSync: () {},
              onConflicts: () {},
              onPending: () => showModalBottomSheet<void>(
                context: context,
                builder: (_) => SyncPendingSheet(
                  issues: const [
                    SyncPendingViewData(
                      id: 3,
                      title: 'CREAR PROSPECTO',
                      message:
                          'No se pudo conectar. El cambio queda pendiente.',
                      attemptCount: 2,
                    ),
                  ],
                  onRetry: (_) async => retried++,
                ),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('VER DETALLE'));
    await tester.pumpAndSettle();

    expect(find.byType(SyncPendingSheet), findsOneWidget);
    expect(find.text('CREAR PROSPECTO'), findsOneWidget);
    expect(
      find.text('No se pudo conectar. El cambio queda pendiente.'),
      findsOneWidget,
    );
    expect(find.text('Intentos: 2'), findsOneWidget);

    await tester.tap(find.text('REINTENTAR'));
    await tester.pumpAndSettle();
    expect(retried, 1);
    expect(find.byType(SyncPendingSheet), findsNothing);
  });
}
