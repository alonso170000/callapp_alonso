import 'package:callerapp_frontend/presentation/widgets/app_press_bounce.dart';

import 'dart:async';

import 'package:callerapp_frontend/presentation/models/call_models.dart';
import 'package:callerapp_frontend/services/cube_acr_audio_service.dart';
import 'package:flutter/material.dart';

import '../app_bottom_sheet.dart';

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
    required this.endedAt,
    this.durationEstimated = true,
    this.audioService,
  });

  final String name;
  final Duration duration;
  final String phone;

  /// Instante real en el que se abrió el marcador. Se usa para localizar la
  /// grabación porque los archivos de Cube ACR usan la hora del dispositivo.
  final DateTime startedAt;

  /// Instante real en el que terminó la llamada.
  final DateTime endedAt;
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

  Future<void> _findAudio() async {
    if (!_configured) return;
    setState(() {
      _searching = true;
      _audioMessage = null;
    });
    try {
      List<CubeAcrAudioCandidate> candidates = const [];
      for (var attempt = 0; attempt < 6 && candidates.isEmpty; attempt++) {
        candidates = await _audioService.findCandidates(
          ProspectCallSession(
            startedAt: widget.startedAt,
            endedAt: widget.endedAt,
            outcome: ProspectCallOutcome.other,
            phone: widget.phone,
            origin: 'detalle',
          ),
        );
        if (candidates.isEmpty && attempt < 5) {
          await Future<void>.delayed(const Duration(seconds: 2));
          if (!mounted) return;
        }
      }
      if (!mounted) return;
      if (candidates.isEmpty) {
        setState(
          () =>
              _audioMessage = 'No se encontró una grabación para esta llamada.',
        );
        return;
      }
      var selected = candidates.first;
      if (candidates.length > 1) {
        final changed = await showAppBottomSheet<CubeAcrAudioCandidate>(
          context: context,
          builder: (sheetContext) => AppBottomSheet(
            title: 'Selecciona la grabación',
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (final candidate in candidates)
                  ListTile(
                    onTap: () => Navigator.pop(sheetContext, candidate),
                    title: Text(candidate.name),
                  ),
              ],
            ),
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

  void _selectOutcome(ProspectCallOutcome value) {
    setState(() {
      _outcome = value;
      _audioMessage = null;
      if (value != ProspectCallOutcome.answered) {
        _consent = null;
        _audio = null;
      }
    });
  }

  void _submit() {
    final outcome = _outcome;
    if (outcome == null) {
      setState(() => _audioMessage = 'Selecciona el resultado de la llamada.');
      return;
    }
    if (outcome == ProspectCallOutcome.answered && _consent == null) {
      setState(
        () => _audioMessage =
            'Indica si el prospecto aceptó que se grabe la llamada.',
      );
      return;
    }
    final consent = outcome == ProspectCallOutcome.answered && _consent == true;
    Navigator.pop(
      context,
      ProspectCallClosure(
        outcome: outcome,
        consent: consent,
        audio: consent ? _audio : null,
      ),
    );
  }

  Widget _audioStatus(BuildContext context) {
    final theme = Theme.of(context);
    final audio = _audio;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          Icon(
            audio == null
                ? Icons.audio_file_outlined
                : Icons.check_circle_outline,
            color: theme.colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              audio == null
                  ? 'Aún no se detecta la grabación.'
                  : 'Grabación detectada: ${audio.name}',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          AppPressBounce(
            child: TextButton(
              onPressed: _findAudio,
              child: const Text('BUSCAR'),
            ),
          ),
        ],
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
                    onSelected: (_) => _selectOutcome(value),
                  ),
                )
                .toList(),
          ),
          if (_outcome == ProspectCallOutcome.answered) ...[
            const SizedBox(height: 16),
            const Text('¿El prospecto aceptó que se grabe la llamada?'),
            Wrap(
              spacing: 8,
              children: [
                ChoiceChip(
                  label: const Text('Sí, aceptó'),
                  selected: _consent == true,
                  onSelected: (_) {
                    setState(() {
                      _consent = true;
                      _audioMessage = null;
                    });
                    if (_configured && _audio == null && !_searching) {
                      unawaited(_findAudio());
                    }
                  },
                ),
                ChoiceChip(
                  label: const Text('No aceptó'),
                  selected: _consent == false,
                  onSelected: (_) => setState(() {
                    _consent = false;
                    _audio = null;
                    _audioMessage = null;
                  }),
                ),
              ],
            ),
            if (_consent == true) ...[
              const SizedBox(height: 12),
              if (!_configured)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text(
                    'No hay una carpeta de Cube ACR vinculada. Configúrala desde Mi perfil para adjuntar grabaciones.',
                  ),
                )
              else if (_searching)
                const Center(child: Text('Buscando grabación…'))
              else
                _audioStatus(context),
            ],
          ],
          if (_audioMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(_audioMessage!),
            ),
          const SizedBox(height: 16),
          AppPressBounce(
            child: FilledButton(
              onPressed: _submit,
              child: const Text('GUARDAR RESULTADO'),
            ),
          ),
        ],
      ),
    ),
  );
}
