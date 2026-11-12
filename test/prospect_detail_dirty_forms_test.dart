import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/prospect_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const prospect = ProspectRecord(
    name: 'Ana',
    phone: '9981234567',
    email: 'ana@example.com',
    status: 'Nuevo',
    temperature: 'Tibio',
    avatarColor: Colors.teal,
    statusColor: Colors.blue,
  );

  testWidgets(
    'Discovery conserva cambios al cerrar el chip y confirma antes de salir',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(home: ProspectDetailScreen(prospect: prospect)),
      );
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.text('Registrar discovery'));
      await tester.tap(find.text('Registrar discovery'));
      await tester.pump();
      const emptyKey = ValueKey('¿Qué tipo de propiedad busca? *-null');
      await tester.ensureVisible(find.byKey(emptyKey));
      await tester.tap(find.byKey(emptyKey));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Departamento').last);
      await tester.pumpAndSettle();

      const changedKey = ValueKey(
        '¿Qué tipo de propiedad busca? *-Departamento',
      );
      final changed = tester.widget<DropdownButtonFormField<String>>(
        find.byKey(changedKey),
      );
      final border = changed.decoration.enabledBorder! as OutlineInputBorder;
      expect(border.borderSide.width, 3);

      final discoveryChip = find.widgetWithText(FilterChip, 'Discovery');
      await tester.tap(discoveryChip);
      await tester.pump();
      expect(find.byKey(changedKey), findsNothing);
      expect(find.byKey(changedKey, skipOffstage: false), findsOneWidget);

      await tester.tap(discoveryChip);
      await tester.pump();
      expect(find.byKey(changedKey), findsOneWidget);

      await tester.tap(find.byTooltip('Volver'));
      await tester.pumpAndSettle();
      expect(find.text('Cambios pendientes'), findsOneWidget);
      expect(
        find.text('Tienes cambios sin guardar en: Discovery.'),
        findsOneWidget,
      );
      expect(find.text('SALIR SIN GUARDAR'), findsOneWidget);
    },
  );
}
