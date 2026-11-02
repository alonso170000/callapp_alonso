import 'package:callerapp_frontend/presentation/models/prospect_models.dart';
import 'package:callerapp_frontend/presentation/models/search_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/search_screen.dart';
import 'package:callerapp_frontend/repositories/prospect_search_repository.dart';
import 'package:callerapp_frontend/resources/styles/app_themes.dart';
import 'package:callerapp_frontend/services/prospects_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 11, 2, 12);

  Future<void> pumpSearch(
    WidgetTester tester,
    ProspectSearchRepository repository, {
    ValueChanged<ProspectRecord>? onOpenProspect,
    ThemeData? theme,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        theme: theme,
        home: SearchScreen(
          repository: repository,
          now: () => now,
          onOpenProspect: onOpenProspect,
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('el estado inicial muestra recientes y sugerencias', (
    tester,
  ) async {
    final repository = _FakeSearchRepository(
      SearchSnapshot(
        prospects: [
          _prospect(1, 'Ana', nextContact: DateTime(2026, 11, 2, 9)),
          _prospect(2, 'Luis', assignedAt: DateTime(2026, 11, 1, 9)),
          _prospect(3, 'Marta'),
        ],
        recentSearches: [
          RecentSearch(query: 'Luis', searchedAt: DateTime(2026, 11, 2, 10)),
        ],
        cachedAt: now,
      ),
    );

    await pumpSearch(tester, repository);

    expect(find.text('ÚLTIMOS BUSCADOS'), findsOneWidget);
    expect(find.text('Luis'), findsOneWidget);
    expect(find.text('PROSPECTOS SUGERIDOS'), findsOneWidget);
    expect(find.text('Contacto pendiente'), findsOneWidget);
    expect(find.text('Asignado recientemente'), findsOneWidget);
    expect(find.text('ANA'), findsOneWidget);
    expect(repository.refreshCalls, 0);
    expect(tester.takeException(), isNull);
  });

  testWidgets('escribir filtra y oculta las secciones iniciales', (
    tester,
  ) async {
    final repository = _FakeSearchRepository(
      SearchSnapshot(
        prospects: [_prospect(1, 'Ana'), _prospect(2, 'Luis')],
        recentSearches: const [],
        cachedAt: now,
      ),
    );

    await pumpSearch(tester, repository);
    await tester.enterText(find.byType(TextField), 'ana');
    await tester.pumpAndSettle();

    expect(find.text('ANA'), findsOneWidget);
    expect(find.text('LUIS'), findsNothing);
    expect(find.text('ÚLTIMOS BUSCADOS'), findsNothing);
    expect(find.textContaining('RESULTADOS'), findsOneWidget);
  });

  testWidgets('sin coincidencias muestra el estado vacío', (tester) async {
    final repository = _FakeSearchRepository(
      SearchSnapshot(
        prospects: [_prospect(1, 'Ana')],
        recentSearches: const [],
        cachedAt: now,
      ),
    );

    await pumpSearch(tester, repository);
    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pumpAndSettle();

    expect(find.text('Sin resultados'), findsOneWidget);
    expect(find.textContaining('zzz'), findsWidgets);
  });

  testWidgets('tocar un resultado abre el prospecto y guarda la búsqueda', (
    tester,
  ) async {
    ProspectRecord? opened;
    final repository = _FakeSearchRepository(
      SearchSnapshot(
        prospects: [_prospect(7, 'Ana')],
        recentSearches: const [],
        cachedAt: now,
      ),
    );

    await pumpSearch(
      tester,
      repository,
      onOpenProspect: (prospect) => opened = prospect,
    );
    await tester.enterText(find.byType(TextField), 'ana');
    await tester.pumpAndSettle();
    await tester.tap(find.text('ANA'));
    await tester.pumpAndSettle();

    expect(opened?.id, 7);
    expect(repository.remembered, ['ana']);
    expect(repository.rememberedProspectIds, [7]);
  });

  testWidgets('una caché vacía se completa con el refresco remoto', (
    tester,
  ) async {
    final repository = _FakeSearchRepository(
      const SearchSnapshot(prospects: [], recentSearches: [], cachedAt: null),
      refreshResult: SearchSnapshot(
        prospects: [_prospect(1, 'Ana')],
        recentSearches: const [],
        cachedAt: now,
      ),
    );

    await pumpSearch(tester, repository);

    expect(repository.refreshCalls, 1);
    expect(find.text('ANA'), findsOneWidget);
  });

  testWidgets('un fallo de red conserva los resultados guardados', (
    tester,
  ) async {
    final repository = _FakeSearchRepository(
      SearchSnapshot(
        prospects: [_prospect(1, 'Ana')],
        recentSearches: const [],
        cachedAt: null,
      ),
      refreshError: const ProspectsOfflineException('Sin conexión a Internet.'),
    );

    await pumpSearch(tester, repository);

    expect(repository.refreshCalls, 1);
    expect(find.text('ANA'), findsOneWidget);
    expect(
      find.textContaining('Mostrando resultados guardados'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });

  testWidgets('un error inicial muestra el aviso y permite reintentar', (
    tester,
  ) async {
    final repository = _FailingSearchRepository(
      const ProspectsException('No hay sesión activa.'),
    );

    await pumpSearch(tester, repository);

    expect(find.text('No se pudo cargar'), findsOneWidget);
    expect(find.text('No hay sesión activa.'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('tocar un término reciente lo coloca en el campo', (
    tester,
  ) async {
    final repository = _FakeSearchRepository(
      SearchSnapshot(
        prospects: [_prospect(1, 'Ana')],
        recentSearches: [
          RecentSearch(
            query: 'Ana María',
            searchedAt: DateTime(2026, 11, 2, 10),
          ),
        ],
        cachedAt: now,
      ),
    );

    await pumpSearch(tester, repository);
    await tester.tap(find.text('Ana María'));
    await tester.pumpAndSettle();

    expect(
      tester.widget<TextField>(find.byType(TextField)).controller?.text,
      'Ana María',
    );
    expect(find.text('Sin resultados'), findsOneWidget);
  });

  testWidgets('borrar todo limpia el historial tras confirmar', (tester) async {
    final repository = _FakeSearchRepository(
      SearchSnapshot(
        prospects: [_prospect(1, 'Ana')],
        recentSearches: [
          RecentSearch(query: 'Ana', searchedAt: DateTime(2026, 11, 2, 10)),
        ],
        cachedAt: now,
      ),
    );

    await pumpSearch(tester, repository);
    await tester.tap(find.text('Borrar todo'));
    await tester.pumpAndSettle();
    expect(find.text('Borrar historial'), findsOneWidget);
    await tester.tap(find.text('BORRAR'));
    await tester.pumpAndSettle();

    expect(repository.cleared, isTrue);
    expect(find.text('ÚLTIMOS BUSCADOS'), findsNothing);
  });

  testWidgets('se renderiza sin errores en modo oscuro', (tester) async {
    final repository = _FakeSearchRepository(
      SearchSnapshot(
        prospects: [_prospect(1, 'Ana')],
        recentSearches: [
          RecentSearch(query: 'Ana', searchedAt: DateTime(2026, 11, 2, 10)),
        ],
        cachedAt: now,
      ),
    );

    await pumpSearch(
      tester,
      repository,
      theme: AppThemes.build(Brightness.dark),
    );

    expect(find.text('ANA'), findsOneWidget);
    expect(find.text('ÚLTIMOS BUSCADOS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('expone etiquetas accesibles para volver y abrir resultados', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();
    final repository = _FakeSearchRepository(
      SearchSnapshot(
        prospects: [_prospect(1, 'Ana')],
        recentSearches: const [],
        cachedAt: now,
      ),
    );

    await pumpSearch(tester, repository);

    expect(find.byTooltip('Volver'), findsOneWidget);
    expect(
      find.bySemanticsLabel(RegExp('Abrir prospecto Ana')),
      findsOneWidget,
    );
    semantics.dispose();
  });
}

class _FakeSearchRepository extends ProspectSearchRepository {
  _FakeSearchRepository(this.snapshot, {this.refreshError, this.refreshResult});

  SearchSnapshot snapshot;
  final Object? refreshError;
  final SearchSnapshot? refreshResult;
  int refreshCalls = 0;
  bool cleared = false;
  final List<String> remembered = [];
  final List<int?> rememberedProspectIds = [];
  List<RecentSearch> currentRecent = const [];

  @override
  Future<SearchSnapshot> load() async {
    currentRecent = snapshot.recentSearches;
    return snapshot;
  }

  @override
  Future<SearchSnapshot> refresh() async {
    refreshCalls++;
    final error = refreshError;
    if (error != null) throw error;
    snapshot = refreshResult ?? snapshot;
    currentRecent = snapshot.recentSearches;
    return snapshot;
  }

  @override
  bool isRefreshDue(SearchSnapshot snapshot, {DateTime? now}) =>
      snapshot.cachedAt == null;

  @override
  Future<List<RecentSearch>> rememberQuery(
    String query, {
    ProspectRecord? prospect,
  }) async {
    remembered.add(query);
    rememberedProspectIds.add(prospect?.id);
    currentRecent = [
      RecentSearch(query: query, searchedAt: DateTime(2026, 11, 2, 12)),
    ];
    return currentRecent;
  }

  @override
  Future<List<RecentSearch>> removeQuery(String query) async {
    currentRecent = const [];
    return currentRecent;
  }

  @override
  Future<void> clearHistory() async {
    cleared = true;
    currentRecent = const [];
  }
}

class _FailingSearchRepository extends ProspectSearchRepository {
  _FailingSearchRepository(this.error);

  final ProspectsException error;

  @override
  Future<SearchSnapshot> load() async => throw error;
}

ProspectRecord _prospect(
  int id,
  String name, {
  DateTime? nextContact,
  DateTime? assignedAt,
}) => ProspectRecord(
  id: id,
  name: name,
  phone: '555000000$id',
  email: 'contacto$id@example.com',
  status: 'Nuevo',
  temperature: 'Tibio',
  avatarColor: Colors.teal,
  statusColor: Colors.blue,
  nextContact: nextContact,
  assignedAt: assignedAt,
);
