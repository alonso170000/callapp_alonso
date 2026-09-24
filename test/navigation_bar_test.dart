import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:callerapp_frontend/presentation/widgets/navigation_bar_widget.dart';

void main() {
  for (final width in [320.0, 390.0]) {
    testWidgets(
      'Navbar labels keep their size and inactive icons stay centered at width $width',
      (tester) async {
        tester.view.devicePixelRatio = 1;
        tester.view.physicalSize = Size(width, 844);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetPhysicalSize);
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
        final selections = <int>[];
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: NavigationBarWidget(
                  onDestinationSelected: selections.add,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final searchPosition = tester.getCenter(
          find.byIcon(Iconsax.search_normal_1_copy),
        );
        for (final selected in [1, 2, 3, 0]) {
          await tester.tap(icon(selected));
          await tester.pump(const Duration(milliseconds: 100));
          for (var index = 0; index < 4; index++) {
            if (index != selected) {
              expect(
                tester.getCenter(icon(index)),
                tester.getCenter(slot(index)),
              );
            }
          }
          await tester.pumpAndSettle();
          for (var index = 0; index < 4; index++) {
            if (index != selected) {
              expect(
                tester.getCenter(icon(index)),
                tester.getCenter(slot(index)),
              );
            }
          }
          expect(
            tester.getCenter(find.byIcon(Iconsax.search_normal_1_copy)),
            searchPosition,
          );
          expect(find.byType(FittedBox), findsNothing);
          final label = tester.widget<Text>(
            find.text(['Inicio', 'Prospectos', 'Agenda', 'Perfil'][selected]),
          );
          expect(label.style?.fontSize, 16);
          expect(tester.takeException(), isNull);
        }
        expect(selections, [1, 2, 3, 0]);
      },
    );
  }
}
