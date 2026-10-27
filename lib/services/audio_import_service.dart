import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';

class ImportedCallAudio {
  const ImportedCallAudio({required this.path, required this.name});

  final String path;
  final String name;
}

class AudioImportException implements Exception {
  const AudioImportException(this.message);
  final String message;
}

/// Selecciona mediante SAF y copia el archivo a almacenamiento privado para
/// conservarlo hasta que el outbox pueda subirlo.
class AudioImportService {
  static const _extensions = ['m4a', 'amr', 'wav', 'mp3', '3gp', 'aac', 'ogg'];

  Future<ImportedCallAudio?> select() async {
    final selection = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: _extensions,
    );
    if (selection.isEmpty) return null;
    final file = selection.single;
    if (file.path == null || file.path!.isEmpty) {
      throw const AudioImportException(
        'No se pudo acceder al archivo seleccionado.',
      );
    }
    final source = File(file.path!);
    if (!await source.exists()) {
      throw const AudioImportException(
        'El archivo seleccionado ya no está disponible.',
      );
    }
    final bytes = await source.length();
    if (bytes > 100 * 1024 * 1024) {
      throw const AudioImportException('La grabación no puede superar 100 MB.');
    }
    final directory = Directory(
      path.join((await getApplicationSupportDirectory()).path, 'call_audio'),
    );
    await directory.create(recursive: true);
    final safeName =
        '${DateTime.now().microsecondsSinceEpoch}_${path.basename(file.name)}';
    final target = File(path.join(directory.path, safeName));
    await source.copy(target.path);
    return ImportedCallAudio(path: target.path, name: file.name);
  }

  Future<void> remove(String? filePath) async {
    if (filePath == null || filePath.isEmpty) return;
    final file = File(filePath);
    if (await file.exists()) await file.delete();
  }
}
