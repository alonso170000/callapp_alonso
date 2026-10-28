import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_call_information.dart';
import 'package:callerapp_frontend/resources/colors/colors.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('Call information values keep high contrast', (tester) async {
    final prospect = ProspectRecord(
      name: 'Ana Real',
      phone: '9981234567',
      email: '',
      status: 'Nuevo',
      temperature: 'Caliente',
      avatarColor: Colors.teal,
      statusColor: Colors.orange,
      lastCallAt: DateTime(2026, 10, 15, 16, 46),
      lastCallStatus: 'No contestada',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ProspectCallInformation(prospect: prospect)),
      ),
    );

    final values = tester
        .widgetList<Text>(find.byType(Text))
        .where((text) => text.style?.color == AppColors.prospectFormFieldText)
        .toList();
    expect(values, hasLength(4));
    expect(
      values.every(
        (text) => text.style?.color == AppColors.prospectFormFieldText,
      ),
      isTrue,
    );
  });
}
