import 'package:callerapp_frontend/presentation/widgets/navigation_bar_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

void main() {
  setUpAll(() async {
    final loader = FontLoader(
      'SulphurPoint',
    )..addFont(rootBundle.load('lib/resources/fonts/SulphurPoint-Regular.ttf'));
    await loader.load();
  });

  const labels = ['Inicio', 'Prospectos', 'Agenda', 'Perfil'];
  const inactive = [
    Iconsax.home_2_copy,
    Iconsax.profile_2user_copy,
    Iconsax.calendar_2_copy,
    Iconsax.profile_circle_copy,
  ];
  const active = [
    Iconsax.home_2,
    Iconsax.profile_2user,
    Iconsax.calendar_2,
    Iconsax.profile_circle,
  ];
  Finder icon(int index) => find.byWidgetPredicate(
    (widget) =>
        widget is Icon &&
        (widget.icon == inactive[index] || widget.icon == active[index]),
  );
  Finder slot(int index) => find
      .ancestor(of: icon(index), matching: find.byType(GestureDetector))
      .first;

  Future<void> pumpBar(
    WidgetTester tester, {
    required double width,
    required bool withAddCallbacks,
    double textScale = 1,
  }) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = Size(width, 844);
    addTearDown(tester.view.resetDevicePixelRatio);
    addTearDown(tester.view.resetPhysicalSize);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(textScale)),
          child: child!,
        ),
        home: Scaffold(
          body: Center(
            child: NavigationBarWidget(
              onAddProspect: withAddCallbacks ? () {} : null,
              onAddAgenda: withAddCallbacks ? () {} : null,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  for (final withAddCallbacks in [true, false]) {
    for (final width in [320.0, 360.0, 390.0, 412.0, 480.0]) {
      testWidgets(
        'navbar is responsive at $width with add callbacks: $withAddCallbacks',
        (tester) async {
          await pumpBar(
            tester,
            width: width,
            withAddCallbacks: withAddCallbacks,
          );
          final searchPositions = <bool, Offset>{};
          double? commonFontSize;
          for (final selected in [1, 2, 3, 0]) {
            await tester.tap(icon(selected));
            await tester.pumpAndSettle();
            for (var index = 0; index < 4; index++) {
              if (index != selected) {
                expect(
                  tester.getCenter(icon(index)),
                  tester.getCenter(slot(index)),
                );
              }
            }
            final showsAddButton =
                withAddCallbacks && (selected == 1 || selected == 2);
            final searchPosition = tester.getCenter(
              find.byIcon(Iconsax.search_normal_1_copy),
            );
            searchPositions.putIfAbsent(showsAddButton, () => searchPosition);
            expect(searchPosition, searchPositions[showsAddButton]);
            if (!showsAddButton) {
              expect(
                tester
                    .getCenter(
                      find.byKey(const ValueKey('normal-navigation-bar')),
                    )
                    .dx,
                closeTo(width / 2, 0.01),
              );
            }
            expect(find.byType(FittedBox), findsNothing);
            final labelFinder = find.text(labels[selected]);
            if (labelFinder.evaluate().isNotEmpty) {
              final label = tester.widget<Text>(labelFinder);
              commonFontSize ??= label.style?.fontSize;
              expect(label.style?.fontSize, commonFontSize);
              final paragraph = tester.renderObject<RenderParagraph>(
                labelFinder,
              );
              if (width >= 360) expect(paragraph.didExceedMaxLines, isFalse);
            } else {
              expect(width, 320);
              expect(withAddCallbacks, isTrue);
            }
            expect(tester.takeException(), isNull);
          }
        },
      );
    }
  }

  testWidgets('navbar supports text scale 1.3 at 360 dp', (tester) async {
    await pumpBar(tester, width: 360, withAddCallbacks: true, textScale: 1.3);
    for (final selected in [1, 2, 3, 0]) {
      await tester.tap(icon(selected));
      await tester.pumpAndSettle();
      expect(find.byType(FittedBox), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
