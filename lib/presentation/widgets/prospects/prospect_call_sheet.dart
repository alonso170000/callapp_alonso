import 'package:callerapp_frontend/resources/styles/app_palette.dart';
import 'package:callerapp_frontend/presentation/models/call_models.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:callerapp_frontend/services/audio_import_service.dart';
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
    this.startedAt,
    this.origin = 'detalle',
    this.sourceActivityId,
    this.onFinishSession,
  });

  final String name;
  final String phone;
  final String email;
  final VoidCallback onCopyPhone;
  final Future<String?> Function()? onCallAgain;
  final ValueChanged<bool>? onFinish;
  final VoidCallback? onClose;
  final String? errorMessage;
  final DateTime? startedAt;
  final String origin;
  final int? sourceActivityId;
  final ValueChanged<ProspectCallSession>? onFinishSession;

  @override
  State<ProspectCallSheet> createState() => _ProspectCallSheetState();
}

class _ProspectCallSheetState extends State<ProspectCallSheet> {
  String? _errorMessage;
  bool _retrying = false;
  ProspectCallOutcome _outcome = ProspectCallOutcome.unanswered;
  final _audioImport = AudioImportService();
  ImportedCallAudio? _audio;
  bool _consentConfirmed = false;
  bool _importingAudio = false;

  Future<void> _importAudio() async {
    if (_importingAudio) return;
    setState(() => _importingAudio = true);
    try {
      final selected = await _audioImport.select();
      if (!mounted || selected == null) return;
      setState(() => _audio = selected);
    } on AudioImportException catch (error) {
      if (mounted) setState(() => _errorMessage = error.message);
    } finally {
      if (mounted) setState(() => _importingAudio = false);
    }
  }

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
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _consentConfirmed,
                onChanged: (value) =>
                    setState(() => _consentConfirmed = value ?? false),
                title: const Text(
                  'Confirmo que el prospecto fue informado y aceptó la grabación.',
                ),
                controlAffinity: ListTileControlAffinity.leading,
              ),
              OutlinedButton.icon(
                onPressed: !_consentConfirmed || _importingAudio
                    ? null
                    : _importAudio,
                icon: _importingAudio
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.audio_file_outlined),
                label: Text(
                  _audio == null
                      ? 'IMPORTAR GRABACIÓN NATIVA'
                      : 'GRABACIÓN: ${_audio!.name}',
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Resultado de la llamada',
                style: Theme.of(context).textTheme.titleSmall,
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: ProspectCallOutcome.values
                    .map(
                      (outcome) => ChoiceChip(
                        label: Text(outcome.label),
                        selected: _outcome == outcome,
                        onSelected: (_) => setState(() => _outcome = outcome),
                      ),
                    )
                    .toList(),
              ),
              const SizedBox(height: 8),
              FilledButton.icon(
                key: const ValueKey('finish-prospect-call'),
                onPressed: !_consentConfirmed
                    ? null
                    : () {
                        final session = ProspectCallSession(
                          startedAt: widget.startedAt ?? businessNow(),
                          endedAt: businessNow(),
                          outcome: _outcome,
                          phone: widget.phone,
                          origin: widget.origin,
                          sourceActivityId: widget.sourceActivityId,
                          audioPath: _audio?.path,
                          audioName: _audio?.name,
                        );
                        widget.onFinishSession?.call(session);
                        widget.onFinish!(_outcome.successful);
                      },
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
}
