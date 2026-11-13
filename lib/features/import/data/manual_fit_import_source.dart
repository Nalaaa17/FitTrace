import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:metrics_engine/metrics_engine.dart';
import 'package:path/path.dart' as p;

import '../domain/activity_import_source.dart';

/// Multi-select manual `.FIT` picker source (PRD M1-08).
///
/// Uses `FileType.any` on mobile SAF so `.fit` files aren't hidden by strict
/// OS extension/MIME filters, then filters `.fit` extension or `.FIT` header.
class ManualFilePickerSource implements ActivityImportSource {
  const ManualFilePickerSource();

  @override
  ActivitySource get sourceType => ActivitySource.manualImport;

  @override
  Future<List<ImportCandidate>> fetchCandidates() async {
    final files = await FilePicker.pickFiles(
      type: FileType.any,
    );
    if (files.isEmpty) {
      return const <ImportCandidate>[];
    }

    final candidates = <ImportCandidate>[];
    for (final picked in files) {
      final path = picked.path;
      if (path != null) {
        final file = File(path);
        if (await _looksLikeFitFile(file, picked.name)) {
          candidates.add(
            ImportCandidate(
              source: ActivitySource.manualImport,
              file: file,
            ),
          );
        }
      } else {
        final isFitByName = picked.name.toLowerCase().endsWith('.fit');
        if (isFitByName || await _looksLikeFitStream(picked.readAsByteStream())) {
          candidates.add(
            ImportCandidate(
              source: ActivitySource.manualImport,
              streamFactory: picked.readAsByteStream,
              suggestedTitle: p.basenameWithoutExtension(picked.name),
            ),
          );
        }
      }
    }
    return candidates;
  }
}

/// Source wrapping local `.fit` file paths delivered via OS Share Intent.
class SharedFilesImportSource implements ActivityImportSource {
  const SharedFilesImportSource(this.filePaths);

  final List<String> filePaths;

  @override
  ActivitySource get sourceType => ActivitySource.manualImport;

  @override
  Future<List<ImportCandidate>> fetchCandidates() async {
    final candidates = <ImportCandidate>[];
    for (final path in filePaths) {
      final file = File(path);
      if (!await file.exists()) continue;
      if (await _looksLikeFitFile(file, p.basename(path))) {
        candidates.add(
          ImportCandidate(
            source: ActivitySource.manualImport,
            file: file,
          ),
        );
      }
    }
    return candidates;
  }
}

Future<bool> _looksLikeFitFile(File file, String fileName) async {
  if (fileName.toLowerCase().endsWith('.fit')) return true;
  try {
    final raf = await file.open();
    try {
      final header = await raf.read(14);
      return _hasFitHeader(header);
    } finally {
      await raf.close();
    }
  } on Object {
    return false;
  }
}

Future<bool> _looksLikeFitStream(Stream<List<int>> stream) async {
  final header = <int>[];
  await for (final chunk in stream) {
    for (final b in chunk) {
      header.add(b);
      if (header.length >= 12) {
        return _hasFitHeader(header);
      }
    }
  }
  return _hasFitHeader(header);
}

bool _hasFitHeader(List<int> bytes) {
  if (bytes.length < 12) return false;
  // Standard FIT header bytes 8..11 contain ASCII ".FIT".
  return bytes[8] == 0x2E &&
      bytes[9] == 0x46 &&
      bytes[10] == 0x49 &&
      bytes[11] == 0x54;
}
