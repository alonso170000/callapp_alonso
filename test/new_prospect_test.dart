import 'dart:convert';

import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/new_prospect_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'Creates with real catalog IDs and retains form on error at $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetViewInsets);
        var posts = 0;
        final auth = AuthService(
          client: MockClient(
            (_) async =>
                http.Response('{"status":"success","token":"test"}', 200),
          ),
        );
        await auth.login('agente', 'password');
        final service = ProspectsService(
          auth: auth,
          client: MockClient((request) async {
            expect(request.headers['Authorization'], 'Bearer test');
            if (request.method == 'GET') {
              final channel = request.url.path.endsWith('canales');
              return http.Response(
                jsonEncode({
                  'success': true,
                  'data': [
                    {
                      'id': channel ? 9 : 22,
                      'nombre': channel ? 'Referido' : 'Nuevo',
                    },
                  ],
                }),
                200,
              );
            }
            final body = jsonDecode(request.body) as Map;
            expect(body['canal_id'], 9);
            expect(body['estatus_id'], 22);
            expect(body['nombre'], 'Ana Nueva');
            expect(body['telefono_normalizado'], '9981234567');
            expect(body['calificacion'], isEmpty);
            expect(body.containsKey('agente_id'), isFalse);
            posts++;
            if (posts == 1) {
              return http.Response(
                '{"success":false,"message":"Revisa los datos"}',
                400,
              );
            }
            return http.Response('{"success":true,"data":{"id":33}}', 201);
          }),
        );
        addTearDown(service.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) => TextButton(
                  onPressed: () async {
                    final result = await showModalBottomSheet<bool>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => NewProspectSheet(service: service),
                    );
                    if (context.mounted && result == true) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(const SnackBar(content: Text('Creado')));
                    }
                  },
                  child: const Text('Abrir'),
                ),
              ),
            ),
          ),
        );
        await tester.tap(find.text('Abrir'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('save-prospect')));
        await tester.pumpAndSettle();
        expect(posts, 0);
        expect(find.text('Este campo es obligatorio'), findsWidgets);
        tester.view.viewInsets = const FakeViewPadding(bottom: 260);
        for (final entry in {
          'Nombre': 'Ana Nueva',
          'Email': 'ana@example.com',
          'Ciudad': 'Cancun',
          'Teléfono': '(998) 123-4567',
        }.entries) {
          final field = find.byKey(ValueKey('prospect-${entry.key}'));
          await tester.ensureVisible(field);
          await tester.enterText(field, entry.value);
        }
        await tester.tap(find.byKey(const ValueKey('save-prospect')));
        await tester.pumpAndSettle();
        expect(posts, 1);
        expect(find.byType(NewProspectSheet), findsOneWidget);
        expect(
          tester
              .widget<TextFormField>(
                find.byKey(const ValueKey('prospect-Nombre')),
              )
              .controller!
              .text,
          'Ana Nueva',
        );
        await tester.tap(find.byKey(const ValueKey('save-prospect')));
        await tester.pumpAndSettle();
        expect(posts, 2);
        expect(find.byType(NewProspectSheet), findsNothing);
        expect(find.text('Creado'), findsOneWidget);
        expect(tester.takeException(), isNull);
      },
    );
  }
}
