import 'package:callerapp_frontend/presentation/models/call_models.dart';
import 'package:callerapp_frontend/services/cube_acr_audio_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('detects Cube ACR audio using Android modification time', () {
    final call = ProspectCallSession(
      startedAt: DateTime(2026, 11, 3, 10),
      endedAt: DateTime(2026, 11, 3, 10, 5),
      outcome: ProspectCallOutcome.answered,
      phone: '9981234567',
      origin: 'detalle',
    );
    final candidates = CubeAcrAudioService.candidatesFromRaw([
      {
        'uri': 'content://cube/motorola-recording',
        'name': 'Llamada con Ana.m4a',
        'modifiedAtMs': DateTime(2026, 11, 3, 10, 5).millisecondsSinceEpoch,
      },
      {
        'uri': 'content://cube/classic-recording',
        'name': 'phone_20261103-100000_9981234567.amr',
        'modifiedAtMs': 0,
      },
      {
        'uri': 'content://cube/motorola-shifted-clock',
        'name': 'phone_20261103-090400_9981234567.amr',
        'modifiedAtMs': DateTime(2026, 11, 3, 10, 4, 30).millisecondsSinceEpoch,
      },
      {
        'uri': 'content://cube/other-number',
        'name': 'phone_20261103-100100_9987654321.amr',
        'modifiedAtMs': 0,
      },
    ], call);

    expect(candidates.map((candidate) => candidate.name), [
      'Llamada con Ana.m4a',
      'phone_20261103-090400_9981234567.amr',
      'phone_20261103-100000_9981234567.amr',
    ]);
  });
}
