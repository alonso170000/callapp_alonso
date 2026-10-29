import 'package:callerapp_frontend/presentation/models/call_models.dart';
import 'package:callerapp_frontend/services/cube_acr_audio_service.dart';
import 'package:callerapp_frontend/services/business_clock.dart';
import 'package:flutter/material.dart';

class ProspectCallClosure {
  const ProspectCallClosure({
    required this.outcome,
    required this.consent,
    this.audio,
  });

  final ProspectCallOutcome outcome;
  final bool consent;
  final ImportedCallAudio? audio;
}

class ProspectCallResultSheet extends StatefulWidget {
  const ProspectCallResultSheet({
    super.key,
    required this.name,
    required this.duration,
    required this.phone,
    required this.startedAt,
    this.durationEstimated = true,
    this.audioService,
  });

  final String name;
  final Duration duration;
  final String phone;
  final DateTime startedAt;
  final bool durationEstimated;
  final CubeAcrAudioService? audioService;

  @override
  State<ProspectCallResultSheet> createState() =>
      _ProspectCallResultSheetState();
}

class _ProspectCallResultSheetState extends State<ProspectCallResultSheet> {
  late final CubeAcrAudioService _audioService;
  ProspectCallOutcome? _outcome;
  bool? _consent;
  bool _configured = false;
  bool _searching = false;
  ImportedCallAudio? _audio;
  String? _audioMessage;

  @override
  void initState() {
    super.initState();
    _audioService = widget.audioService ?? CubeAcrAudioService();
    _loadFolder();
  }

  Future<void> _loadFolder() async {
    try {
      final configured = await _audioService.hasFolder();
      if (mounted) setState(() => _configured = configured);
    } on AudioImportException catch (error) {
      if (mounted) setState(() => _audioMessage = error.message);
    }
  }

  Future<void> _linkFolder() async {
    final name = await _audioService.linkFolder();
    if (!mounted || name == null) return;
    setState(() => _configured = true);
    await _findAudio();
  }

  Future<void> _findAudio() async {
    setState(() {
      _searching = true;
      _audioMessage = null;
    });
    try {
      final candidates = await _audioService.findCandidates(
        ProspectCallSession(
          startedAt: widget.startedAt,
          endedAt: businessNow(),
          outcome: ProspectCallOutcome.other,
          phone: widget.phone,
          origin: 'detalle',
        ),
      );
      if (!mounted) return;
      if (candidates.isEmpty) {
        setState(() => _audioMessage = 'No se detectó una grabación');
        return;
      }
      var selected = candidates.first;
      if (candidates.length > 1) {
        final changed = await showDialog<CubeAcrAudioCandidate>(
          context: context,
          builder: (dialogContext) => SimpleDialog(
            title: const Text('Selecciona la grabación'),
            children: [
              for (final candidate in candidates)
                SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, candidate),
                  child: Text(candidate.name),
                ),
            ],
          ),
        );
        if (changed != null) selected = changed;
      }
      final audio = await _audioService.copyToPrivate(selected);
      if (mounted) setState(() => _audio = audio);
    } on AudioImportException catch (error) {
      if (mounted) setState(() => _audioMessage = error.message);
    } finally {
      if (mounted) setState(() => _searching = false);
    }
  }

  String get _durationLabel {
    final minutes = widget.duration.inMinutes.toString().padLeft(2, '0');
    final seconds = (widget.duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  void _submit() {
    if (_outcome == null || _consent == null) {
      setState(
        () => _audioMessage = 'Selecciona el resultado y el consentimiento.',
      );
      return;
    }
    Navigator.pop(
      context,
      ProspectCallClosure(
        outcome: _outcome!,
        consent: _consent!,
        audio: _consent! ? _audio : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SingleChildScrollView(
      padding: EdgeInsets.fromLTRB(
        24,
        8,
        24,
        24 + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.name, style: Theme.of(context).textTheme.titleLarge),
          Text(
            '${widget.durationEstimated ? 'Duración estimada · ' : 'Duración · '}$_durationLabel',
          ),
          const SizedBox(height: 16),
          const Text('Resultado de la llamada'),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: ProspectCallOutcome.values
                .map(
                  (value) => ChoiceChip(
                    label: Text(value.label),
                    selected: _outcome == value,
                    onSelected: (_) => setState(() => _outcome = value),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 16),
          const Text('¿El prospecto aceptó la grabación?'),
          Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('Sí, aceptó'),
                selected: _consent == true,
                onSelected: (_) => setState(() => _consent = true),
              ),
              ChoiceChip(
                label: const Text('No aceptó'),
                selected: _consent == false,
                onSelected: (_) => setState(() {
                  _consent = false;
                  _audio = null;
                }),
              ),
            ],
          ),
          if (_consent == true) ...[
            const SizedBox(height: 12),
            if (!_configured)
              OutlinedButton(
                onPressed: _linkFolder,
                child: const Text('VINCULAR CARPETA DE CUBE ACR'),
              )
            else if (_searching)
              const Center(child: Text('Buscando grabación…'))
            else
              OutlinedButton(
                onPressed: _findAudio,
                child: Text(
                  _audio == null
                      ? 'BUSCAR NUEVAMENTE'
                      : 'Grabación detectada: ${_audio!.name}',
                ),
              ),
          ],
          if (_audioMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_audioMessage!),
            ),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _submit,
            child: const Text('REGISTRAR LLAMADA'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('SEGUIR EN LA LLAMADA'),
          ),
        ],
      ),
    ),
  );
}
