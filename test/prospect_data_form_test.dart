import 'package:callerapp_frontend/data/local/catalog_cache.dart';
import 'package:callerapp_frontend/data/local/local_scope.dart';
import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/widgets/prospects/prospect_data_form.dart';
import 'package:callerapp_frontend/repositories/prospects_repository.dart';
import 'package:callerapp_frontend/services/auth_service.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('edición carga desarrollo y lotes cacheados sin red', (
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
    final cache = _MemoryCatalogCache();
    const scope = LocalScope(userId: 3, developmentId: 4);
    await cache.write(scope, 'desarrollos', const [
      {'id': 4, 'nombre': 'Runa'},
    ]);
    await cache.write(scope, 'lotes:4', const [
      {'id': 7, 'numero_lote': 23},
    ]);
    final service = _OfflineInterestsService(auth: auth);
    final repository = ProspectsRepository(
      auth: auth,
      service: service,
      catalogs: cache,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: ProspectDataForm(
              prospect: const ProspectRecord(
                id: 10,
                name: 'Ana',
                phone: '9980000000',
                email: 'ana@example.com',
                status: 'Nuevo',
                temperature: 'Tibio',
                avatarColor: Colors.teal,
                statusColor: Colors.blue,
                channelId: 9,
                statusId: 1,
                interestDevelopmentId: 4,
                interestLotId: 7,
              ),
              onSaved: (_) {},
              prospectsService: service,
              repository: repository,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Runa'), findsOneWidget);
    expect(find.text('Lote 23'), findsOneWidget);
    expect(find.text('Sin conexión'), findsNothing);
  });
}

class _OfflineInterestsService extends ProspectsService {
  _OfflineInterestsService({required super.auth});

  @override
  Future<List<Map<String, dynamic>>> availableDevelopments() async =>
      throw const ProspectsRecoverableException('Sin conexión');

  @override
  Future<List<Map<String, dynamic>>> availableLots([
    int? developmentId,
  ]) async => throw const ProspectsRecoverableException('Sin conexión');

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
