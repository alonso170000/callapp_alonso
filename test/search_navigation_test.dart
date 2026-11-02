import 'package:callerapp_frontend/presentation/models/search_models.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/home_screen.dart';
import 'package:callerapp_frontend/presentation/screens/main_screens/search_screen.dart';
import 'package:callerapp_frontend/repositories/prospect_search_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

void main() {
  testWidgets('el navbar abre el buscador global y permite volver', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);

    final router = GoRouter(
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/home',
          builder: (context, state) => HomeScreen(
            loadActivities: () async => const [],
            loadProspects: () async => const [],
          ),
        ),
        GoRoute(
          path: '/buscar',
          builder: (context, state) => SearchScreen(
            repository: _EmptySearchRepository(),
            now: () => DateTime(2026, 11, 2, 12),
          ),
        ),
      ],
    );

    await tester.pumpWidget(MaterialApp.router(routerConfig: router));
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Iconsax.search_normal_1_copy));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay sugerencias'), findsOneWidget);
    expect(find.byTooltip('Volver'), findsOneWidget);

    await tester.tap(find.byTooltip('Volver'));
    await tester.pumpAndSettle();

    expect(find.text('Aún no hay sugerencias'), findsNothing);
    expect(find.byIcon(Iconsax.search_normal_1_copy), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _EmptySearchRepository extends ProspectSearchRepository {
  @override
  Future<SearchSnapshot> load() async =>
      const SearchSnapshot(prospects: [], recentSearches: []);

  @override
  Future<SearchSnapshot> refresh() async =>
      const SearchSnapshot(prospects: [], recentSearches: []);

  @override
  bool isRefreshDue(SearchSnapshot snapshot, {DateTime? now}) => false;
}
