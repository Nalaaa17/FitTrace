import 'dart:typed_data';

import 'models/hr_zone_config.dart';
import 'models/parsed_activity.dart';

/// Pure Dart contract for parsing FIT binaries into normalized metrics.
///
/// Full implementation is scheduled for Phase 1.
abstract interface class FitParserEngine {
  ParsedActivity parseFitBytes(
    Uint8List bytes, {
    required HrZoneConfig hrZoneConfig,
    int? garminActivityId,
    String? fallbackTitle,
  });
}

/// Exception thrown when a FIT file cannot be decoded or fails CRC validation.
class FitParseException implements Exception {
  const FitParseException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'FitParseException: $message';
}

