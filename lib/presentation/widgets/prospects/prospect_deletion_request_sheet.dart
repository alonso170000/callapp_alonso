import 'package:callerapp_frontend/presentation/widgets/app_press_bounce.dart';
import 'package:callerapp_frontend/resources/styles/styles.dart';
import 'package:flutter/material.dart';

enum ProspectDeletionReason {
  duplicate('Lead duplicado'),
  wrongPhone('Teléfono incorrecto'),
  unreachable('Ilocalizable'),
  accidental('Registro accidental'),
  test('Registro de prueba'),
  insufficientBudget('Presupuesto insuficiente'),
  paymentScheme('No le convence el esquema de pago o financiamiento'),
  unmetExpectations('Producto no cumple con sus expectativas'),
  other('Otro');

  const ProspectDeletionReason(this.label);
  final String label;
}

class ProspectDeletionRequestSheet extends StatefulWidget {
  const ProspectDeletionRequestSheet({super.key});

  @override
  State<ProspectDeletionRequestSheet> createState() =>
      _ProspectDeletionRequestSheetState();
}

class _ProspectDeletionRequestSheetState
    extends State<ProspectDeletionRequestSheet> {
  final _otherController = TextEditingController();
  ProspectDeletionReason? _selected;

  bool get _canSubmit =>
      _selected != null &&
      (_selected != ProspectDeletionReason.other ||
          _otherController.text.trim().isNotEmpty);

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_canSubmit) return;
    final reason = _selected == ProspectDeletionReason.other
        ? _otherController.text.trim()
        : _selected!.label;
    Navigator.pop(context, reason);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return SafeArea(
      top: false,
      child: Padding(
        padding: EdgeInsets.only(
          left: AppStyles.cardPaddingHorizontal(context),
          right: AppStyles.cardPaddingHorizontal(context),
          bottom:
              MediaQuery.viewInsetsOf(context).bottom +
              AppStyles.spacingLarge(context),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Solicitar eliminación',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontFamily: 'BebasNeue',
                fontSize: 28,
                color: colors.onSurface,
              ),
            ),
            SizedBox(height: AppStyles.spacingTiny(context)),
            const Text(
              'Selecciona un motivo. Solo puedes elegir una opción.',
              textAlign: TextAlign.center,
            ),
            SizedBox(height: AppStyles.spacingSmall(context)),
            Flexible(
              child: SingleChildScrollView(
                keyboardDismissBehavior:
                    ScrollViewKeyboardDismissBehavior.onDrag,
                child: Column(
                  children: [
                    for (final reason in ProspectDeletionReason.values)
                      RadioListTile<ProspectDeletionReason>(
                        value: reason,
                        groupValue: _selected,
                        contentPadding: EdgeInsets.zero,
                        dense: true,
                        title: Text(reason.label),
                        onChanged: (value) => setState(() {
                          _selected = value;
                          if (value != ProspectDeletionReason.other) {
                            _otherController.clear();
                          }
                        }),
                      ),
                    if (_selected == ProspectDeletionReason.other) ...[
                      SizedBox(height: AppStyles.spacingTiny(context)),
                      TextField(
                        key: const ValueKey('other-deletion-reason'),
                        controller: _otherController,
                        autofocus: true,
                        maxLength: 255,
                        maxLines: 3,
                        textCapitalization: TextCapitalization.sentences,
                        decoration: const InputDecoration(
                          labelText: 'Escribe el motivo',
                          hintText: 'Describe por qué solicitas eliminarlo',
                        ),
                        onChanged: (_) => setState(() {}),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            SizedBox(height: AppStyles.spacingMedium(context)),
            Row(
              children: [
                Expanded(
                  child: AppPressBounce(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('CANCELAR'),
                    ),
                  ),
                ),
                SizedBox(width: AppStyles.spacingSmall(context)),
                Expanded(
                  child: AppPressBounce(
                    enabled: _canSubmit,
                    child: FilledButton(
                      key: const ValueKey('submit-deletion-request'),
                      onPressed: _canSubmit ? _submit : null,
                      child: const Text('SOLICITAR'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
