import 'package:flutter/material.dart';

import '../../resources/styles/styles.dart';
import 'app_press_bounce.dart';

Future<T?> showAppBottomSheet<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool isDismissible = true,
  bool enableDrag = true,
  Color? barrierColor,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  bool showDragHandle = true,
  Color? backgroundColor,
  ShapeBorder? shape,
  Clip? clipBehavior,
}) {
  FocusManager.instance.primaryFocus?.unfocus();
  final scheme = Theme.of(context).colorScheme;
  return showModalBottomSheet<T>(
    context: context,
    builder: builder,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    showDragHandle: showDragHandle,
    isDismissible: isDismissible,
    enableDrag: enableDrag,
    backgroundColor: backgroundColor ?? scheme.surface,
    barrierColor: barrierColor ?? scheme.scrim.withValues(alpha: 0.54),
    shape:
        shape ??
        const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppStyles.sheetRadius),
          ),
        ),
    clipBehavior: clipBehavior ?? Clip.antiAlias,
  );
}

Future<bool?> showAppConfirmationSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String secondaryLabel,
  required String primaryLabel,
  Key? secondaryKey,
  Key? primaryKey,
}) => showAppBottomSheet<bool>(
  context: context,
  builder: (sheetContext) => AppBottomSheet(
    title: title,
    footer: AppSheetActions(
      secondaryLabel: secondaryLabel,
      secondaryKey: secondaryKey,
      onSecondary: () => Navigator.pop(sheetContext, false),
      primaryLabel: primaryLabel,
      primaryKey: primaryKey,
      onPrimary: () => Navigator.pop(sheetContext, true),
    ),
    child: Text(message),
  ),
);

Future<void> showAppMessageSheet({
  required BuildContext context,
  required String title,
  required String message,
  required String actionLabel,
}) => showAppBottomSheet<void>(
  context: context,
  builder: (sheetContext) => AppBottomSheet(
    title: title,
    footer: AppSheetActions(
      primaryLabel: actionLabel,
      onPrimary: () => Navigator.pop(sheetContext),
    ),
    child: Text(message),
  ),
);

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.footer,
    this.scrollable = true,
    this.canClose = true,
    this.onClose,
    this.maxHeightFactor = 0.9,
  });

  final String? title;
  final Widget child;
  final Widget? footer;
  final bool scrollable;
  final bool canClose;
  final VoidCallback? onClose;
  final double maxHeightFactor;

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.viewInsetsOf(context);
    final maxHeight = MediaQuery.sizeOf(context).height * maxHeightFactor;
    final body = scrollable
        ? SingleChildScrollView(
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            child: child,
          )
        : child;

    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: maxHeight),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 4, 24, 18),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (title != null)
                  Row(
                    children: [
                      const SizedBox(width: 48),
                      Expanded(
                        child: Text(
                          title!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: sheetHeadingStyle.copyWith(
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                      ),
                      SizedBox(
                        width: 48,
                        child: canClose
                            ? AppPressBounce(
                                child: IconButton(
                                  tooltip: 'Cerrar',
                                  onPressed:
                                      onClose ?? () => Navigator.pop(context),
                                  icon: const Icon(Icons.close, size: 28),
                                ),
                              )
                            : null,
                      ),
                    ],
                  ),
                Flexible(child: body),
                if (footer != null) ...[const SizedBox(height: 12), footer!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class AppSheetActions extends StatelessWidget {
  const AppSheetActions({
    super.key,
    this.secondaryLabel,
    this.onSecondary,
    this.secondaryKey,
    required this.primaryLabel,
    required this.onPrimary,
    this.primaryKey,
    this.primaryEnabled = true,
    this.secondaryEnabled = true,
  });

  final String? secondaryLabel;
  final VoidCallback? onSecondary;
  final Key? secondaryKey;
  final String primaryLabel;
  final VoidCallback onPrimary;
  final Key? primaryKey;
  final bool primaryEnabled;
  final bool secondaryEnabled;

  Widget _label(String label) => FittedBox(
    fit: BoxFit.scaleDown,
    child: Text(label, style: sheetActionTextStyle),
  );

  @override
  Widget build(BuildContext context) {
    final secondary = secondaryLabel == null
        ? null
        : AppPressBounce(
            enabled: secondaryEnabled,
            child: TextButton(
              key: secondaryKey,
              onPressed: secondaryEnabled ? onSecondary : null,
              style: TextButton.styleFrom(
                minimumSize: const Size(0, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: _label(secondaryLabel!),
            ),
          );
    final primary = AppPressBounce(
      enabled: primaryEnabled,
      child: FilledButton(
        key: primaryKey,
        onPressed: primaryEnabled ? onPrimary : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, 44),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: _label(primaryLabel),
      ),
    );

    if (secondary == null) {
      return SizedBox(width: double.infinity, child: primary);
    }
    return Row(
      children: [
        Expanded(child: secondary),
        const SizedBox(width: 12),
        Expanded(child: primary),
      ],
    );
  }
}

class AppSheetSectionTitle extends StatelessWidget {
  const AppSheetSectionTitle(this.data, {super.key});

  final String data;

  @override
  Widget build(BuildContext context) => Text(
    data,
    style: sheetSectionStyle.copyWith(
      color: Theme.of(context).colorScheme.onSurface,
    ),
  );
}
