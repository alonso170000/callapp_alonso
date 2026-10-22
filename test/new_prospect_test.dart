import 'dart:convert';

import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:callerapp_frontend/data/local/catalog_cache.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/data/local/pending_operations_store.dart';
import 'package:callerapp_frontend/data/local/prospects_cache.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
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
            (_) async => http.Response(
              '{"status":"success","token":"test","usuario":{"id":3},"desarrollo_activo":{"id":4,"nombre":"Runa"}}',
              200,
            ),
          ),
        );
        await auth.login('agente', 'password');
        final service = ProspectsService(
          auth: auth,
          client: MockClient((request) async {
            expect(request.headers['Authorization'], 'Bearer test');
            if (request.method == 'GET') {
              if (request.url.path.endsWith('lotes')) {
                return http.Response(
                  '{"success":true,"data":[{"id":7,"numero_lote":23,"dimensiones_m2":"300.00","tipo":"comercial","precio":"500000.00","estatus":"disponible"}]}',
                  200,
                );
              }
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
            expect(body['prioridad'], 'caliente');
            expect(body['nombre'], 'Ana Nueva');
            expect(body['telefono_normalizado'], '9981234567');
            expect(body['calificacion'], isEmpty);
            expect(body['lote_id'], isNull);
            expect(body['primer_seguimiento']['tipo'], 'seguimiento');
            expect(body['primer_seguimiento']['medio'], 'llamada');
            expect(
              body['primer_seguimiento']['descripcion'],
              'Enviar información del desarrollo',
            );
            expect(body['primer_seguimiento']['recordatorio_at'], isNotNull);
            final scheduledAt = DateTime.parse(
              body['primer_seguimiento']['programada_at'] as String,
            );
            final reminderAt = DateTime.parse(
              body['primer_seguimiento']['recordatorio_at'] as String,
            );
            expect(scheduledAt.isUtc, isTrue);
            expect(reminderAt.isUtc, isTrue);
            expect(reminderAt.isBefore(scheduledAt), isTrue);
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
        await tester.ensureVisible(find.text('Caliente'));
        await tester.tap(find.text('Caliente'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Caliente').last);
        await tester.pumpAndSettle();
        await tester.ensureVisible(
          find.byKey(const ValueKey('first-follow-up')),
        );
        await tester.tap(find.text('No, por ahora'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Sí, agregar seguimiento').last);
        await tester.pumpAndSettle();
        expect(find.text('Medio de contacto*'), findsOneWidget);
        expect(find.text('Recordatorio*'), findsOneWidget);
        expect(find.text('Sin recordatorio'), findsNothing);
        final description = find.byKey(
          const ValueKey('prospect-Descripción del primer seguimiento'),
        );
        await tester.ensureVisible(description);
        await tester.enterText(
          description,
          'Enviar información del desarrollo',
        );
        await tester.ensureVisible(find.byKey(const ValueKey('save-prospect')));
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

  testWidgets('usa catálogos cacheados sin conexión', (tester) async {
    final auth = await _auth();
    final cache = _MemoryCatalogCache();
    const scope = LocalScope(userId: 3, developmentId: 4);
    await cache.write(scope, 'canales', const [
      {'id': 9, 'nombre': 'Referido'},
    ]);
    await cache.write(scope, 'estatus-prospecto', const [
      {'id': 22, 'nombre': 'Nuevo'},
    ]);
    final service = _OfflineCatalogService(auth: auth);
    final repository = ProspectsRepository(
      auth: auth,
      service: service,
      catalogs: cache,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewProspectSheet(service: service, repository: repository),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Origen*'), findsOneWidget);
    expect(find.text('Status*'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('save-prospect')))
          .onPressed,
      isNotNull,
    );
  });

  testWidgets('sin caché explica que requiere una primera conexión', (
    tester,
  ) async {
    final auth = await _auth();
    final service = _OfflineCatalogService(auth: auth);
    final repository = ProspectsRepository(
      auth: auth,
      service: service,
      catalogs: _MemoryCatalogCache(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NewProspectSheet(service: service, repository: repository),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(
      find.textContaining('Conéctate una vez para descargarlos'),
      findsOneWidget,
    );
    expect(find.text('Reintentar'), findsOneWidget);
    expect(
      tester
          .widget<FilledButton>(find.byKey(const ValueKey('save-prospect')))
          .onPressed,
      isNull,
    );
  });

  testWidgets('sin conexión encola el prospecto y lo cachea', (tester) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetViewInsets);

    final auth = await _auth();
    const scope = LocalScope(userId: 3, developmentId: 4);
    final catalogs = _MemoryCatalogCache();
    await catalogs.write(scope, 'canales', const [
      {'id': 9, 'nombre': 'Referido'},
    ]);
    await catalogs.write(scope, 'estatus-prospecto', const [
      {'id': 22, 'nombre': 'Nuevo'},
    ]);
    final service = _OfflineCatalogService(auth: auth);
    final outbox = _MemoryOutbox();
    final prospectsCache = _MemoryProspectsCache();
    final repository = ProspectsRepository(
      auth: auth,
      service: service,
      catalogs: catalogs,
      cache: prospectsCache,
      outbox: outbox,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showModalBottomSheet<bool>(
                context: context,
                isScrollControlled: true,
                builder: (_) =>
                    NewProspectSheet(service: service, repository: repository),
              ),
              child: const Text('Abrir'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();

    tester.view.viewInsets = const FakeViewPadding(bottom: 260);
    for (final entry in {
      'Nombre': 'Ana Offline',
      'Email': 'ana@example.com',
      'Ciudad': 'Cancun',
      'Teléfono': '9981234567',
    }.entries) {
      final field = find.byKey(ValueKey('prospect-${entry.key}'));
      await tester.ensureVisible(field);
      await tester.enterText(field, entry.value);
    }
    await tester.ensureVisible(find.byKey(const ValueKey('save-prospect')));
    await tester.tap(find.byKey(const ValueKey('save-prospect')));
    await tester.pumpAndSettle();

    expect(find.textContaining('Se sincronizará'), findsOneWidget);
    expect(find.byType(NewProspectSheet), findsNothing);
    expect(outbox.operations, hasLength(1));
    expect(outbox.operations.single.kind, 'prospect.create');
    expect(outbox.operations.single.entityId, -1);
    expect(outbox.operations.single.state, PendingOperationState.pending);

    final cached = await prospectsCache.read(scope);
    expect(cached, hasLength(1));
    expect(cached.single.id, -1);
    expect(cached.single.name, 'Ana Offline');
    expect(cached.single.channelId, 9);
  });
}

Future<AuthService> _auth() async {
  final auth = AuthService(
    client: MockClient(
      (_) async => http.Response(
        '{"status":"success","token":"test","usuario":{"id":3},"desarrollo_activo":{"id":4,"nombre":"Runa"}}',
        200,
      ),
    ),
  );
  await auth.login('agente', 'password');
  return auth;
}

class _OfflineCatalogService extends ProspectsService {
  _OfflineCatalogService({required super.auth});

  @override
  Future<List<Map<String, dynamic>>> catalog(String name) async =>
      throw const ProspectsRecoverableException('Sin conexión');

  @override
  Future<List<Map<String, dynamic>>> availableLots([
    int? developmentId,
  ]) async => throw const ProspectsRecoverableException('Sin conexión');

  @override
  Future<int> create(
    Map<String, dynamic> fields, {
    String? operationKey,
  }) async => throw const ProspectsRecoverableException('Sin conexión');

  @override
  void dispose() {}
}

class _MemoryCatalogCache extends CatalogCache {
  final Map<String, List<Map<String, dynamic>>> values = {};

  String _key(LocalScope scope, String name) =>
      '${scope.userId}:${scope.developmentId}:$name';

  @override
  Future<List<Map<String, dynamic>>?> read(
    LocalScope scope,
    String name,
  ) async => values[_key(scope, name)];

  @override
  Future<void> write(
    LocalScope scope,
    String name,
    List<Map<String, dynamic>> rows,
  ) async => values[_key(scope, name)] = rows;
}

class _MemoryProspectsCache extends ProspectsCache {
  final Map<String, List<ProspectRecord>> values = {};

  String _key(LocalScope scope) => '${scope.userId}:${scope.developmentId}';

  @override
  Future<List<ProspectRecord>> read(LocalScope scope) async =>
      values[_key(scope)] ?? const [];

  @override
  Future<void> replace(
    LocalScope scope,
    List<ProspectRecord> prospects,
  ) async => values[_key(scope)] = prospects;

  @override
  Future<void> upsert(LocalScope scope, ProspectRecord prospect) async {
    final current = [...(values[_key(scope)] ?? const <ProspectRecord>[])];
    final index = current.indexWhere((item) => item.id == prospect.id);
    if (index == -1) {
      current.add(prospect);
    } else {
      current[index] = prospect;
    }
    values[_key(scope)] = current;
  }
}

class _MemoryOutbox extends PendingOperationsStore {
  final List<PendingOperation> operations = [];
  int _nextId = 1;

  @override
  bool get isAvailable => true;

  @override
  Future<int?> enqueue(
    LocalScope scope, {
    required String kind,
    required Map<String, dynamic> payload,
    int? entityId,
    String? operationKey,
  }) async {
    final id = _nextId++;
    operations.add(
      PendingOperation(
        id: id,
        scope: scope,
        operationKey: operationKey ?? 'op-$id',
        kind: kind,
        entityId: entityId,
        payload: payload,
        createdAt: businessNow(),
        attemptCount: 0,
        state: PendingOperationState.pending,
      ),
    );
    return id;
  }
}
