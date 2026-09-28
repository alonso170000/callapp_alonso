import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/new_prospect_sheet.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/validators/prospect_validators.dart';

void main() {
  test('Validates prospect contact and numeric fields', () {
    expect(ProspectValidators.email('invalid'), isNotNull);
    expect(ProspectValidators.phone('123'), isNotNull);
    for (final value in ['-1', '1,000', 'NaN', 'Infinity']) {
      expect(ProspectValidators.number(value), isNotNull);
    }
    expect(ProspectValidators.number('120.5'), isNull);
  });
  for (final width in [320.0, 390.0]) {
    testWidgets('Creates prospect from navbar at $width with keyboard', (
      tester,
    ) async {
      tester.view.devicePixelRatio = 1;
      tester.view.physicalSize = Size(width, 844);
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetViewInsets);
      await tester.pumpWidget(const MaterialApp(home: HomeScreen()));
      expect(find.bySemanticsLabel('Agregar prospecto'), findsNothing);
      await tester.tap(find.byIcon(Iconsax.profile_2user_copy));
      await tester.pumpAndSettle();
      expect(find.byIcon(Iconsax.search_normal_1_copy), findsWidgets);
      expect(
        tester.getCenter(find.bySemanticsLabel('Agregar prospecto')).dx,
        lessThan(tester.getCenter(find.byIcon(Iconsax.profile_2user)).dx),
      );
      expect(find.bySemanticsLabel('Buscar prospectos'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Agregar prospecto'));
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('save-prospect')));
      await tester.pumpAndSettle();
      expect(find.byType(NewProspectSheet), findsOneWidget);
      expect(find.text('Este campo es obligatorio'), findsWidgets);
      tester.view.viewInsets = const FakeViewPadding(bottom: 280);
      await tester.pumpAndSettle();
      for (final entry in {
        'Nombre': 'Ana Nueva',
        'Email': 'ana@example.com',
        'Ciudad': 'Cancún',
        'Teléfono': '9981234567',
        'Empresa donde trabaja': 'Empresa',
        'Ocupación': 'Arquitecta',
        'Comentarios del prospecto': 'Interés en lote',
        'Producto': 'Lote residencial',
        'Descripción de Lote': 'Esquina',
        'Dimensión en m² (sin comas)': '120.5',
        'Precio completo del lote': '500000',
      }.entries) {
        final field = find.byKey(ValueKey('prospect-${entry.key}'));
        await tester.ensureVisible(field);
        await tester.enterText(field, entry.value);
      }
      await tester.tap(find.byKey(const ValueKey('save-prospect')));
      await tester.pumpAndSettle();
      tester.view.resetViewInsets();
      await tester.pumpAndSettle();
      expect(find.byType(NewProspectSheet), findsNothing);
      expect(find.text('MOSTRANDO 7 PROSPECTOS'), findsOneWidget);
      final card = tester
          .widgetList<ProspectCard>(find.byType(ProspectCard))
          .firstWhere((c) => c.prospect.name == 'Ana Nueva');
      expect(card.prospect.product, 'Lote residencial');
      expect(card.prospect.dimension, 120.5);
      expect(card.prospect.fullPrice, 500000);
      expect(card.prospect.note, 'Interés en lote');
      expect(card.prospect.appointment, isNull);
      expect(card.prospect.nextContact, isNotNull);
      // Wait for the confirmation snackbar to stop covering the bottom bar.
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel('Agregar prospecto'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();
      expect(find.text('MOSTRANDO 7 PROSPECTOS'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
