import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:flutter/material.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

class ProspectCallSheet extends StatefulWidget {
  const ProspectCallSheet({
    super.key,
    required this.name,
    required this.phone,
    required this.email,
    required this.onCopyPhone,
    this.onCallAgain,
    this.onFinish,
    this.onClose,
    this.errorMessage,
  });

  final String name;
  final String phone;
  final String email;
  final VoidCallback onCopyPhone;
  final Future<String?> Function()? onCallAgain;
  final ValueChanged<bool>? onFinish;
  final VoidCallback? onClose;
  final String? errorMessage;

  @override
  State<ProspectCallSheet> createState() => _ProspectCallSheetState();
}

class _ProspectCallSheetState extends State<ProspectCallSheet> {
  String? _errorMessage;
  bool _retrying = false;
  bool _callSuccessful = false;

  @override
  void initState() {
    super.initState();
    _errorMessage = widget.errorMessage;
  }

  Future<void> _retryCall() async {
    if (_retrying || widget.onCallAgain == null) return;
    setState(() => _retrying = true);
    final errorMessage = await widget.onCallAgain!();
    if (!mounted) return;
    setState(() {
      _retrying = false;
      _errorMessage = errorMessage;
    });
  }

  void _close(BuildContext context) {
    if (widget.onClose != null) {
      widget.onClose!();
      return;
    }
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final palette = AppPalette.of(context);
    return SafeArea(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.name,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            SelectableText(widget.phone, textAlign: TextAlign.center),
            const SizedBox(height: 4),
            SelectableText(widget.email, textAlign: TextAlign.center),
            if (_errorMessage != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: palette.errorSurfaceFill,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: palette.fieldErrorInk),
                ),
              ),
            ],
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: widget.onCopyPhone,
              icon: const Icon(Icons.copy_outlined),
              label: const Text('COPIAR TELÉFONO'),
            ),
            if (widget.onCallAgain != null) ...[
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _retrying ? null : _retryCall,
                icon: _retrying
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Iconsax.call_calling_copy),
                label: const Text('VOLVER A MARCAR'),
              ),
            ],
            if (widget.onFinish != null) ...[
              const SizedBox(height: 8),
              Text('¿Contestó?', style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 6),
              Row(
                children: [
                  Expanded(
                    child: _callOutcomeButton(
                      context,
                      label: 'Sí, contestó',
                      value: true,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _callOutcomeButton(
                      context,
                      label: 'No contestó',
                      value: false,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const ValueKey('finish-prospect-call'),
                onPressed: () => widget.onFinish!(_callSuccessful),
                icon: const Icon(Icons.check_circle_outline),
                label: const Text('TERMINÉ LA LLAMADA'),
              ),
            ],
            const SizedBox(height: 8),
            Semantics(
              button: true,
              label: 'Cerrar panel de llamada',
              child: TextButton(
                onPressed: () => _close(context),
                child: const Text('CERRAR'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _callOutcomeButton(
    BuildContext context, {
    required String label,
    required bool value,
  }) {
    final selected = _callSuccessful == value;
    final child = Text(label, textAlign: TextAlign.center);
    return selected
        ? FilledButton(
            onPressed: () => setState(() => _callSuccessful = value),
            child: child,
          )
        : OutlinedButton(
            onPressed: () => setState(() => _callSuccessful = value),
            child: child,
          );
  }
}
