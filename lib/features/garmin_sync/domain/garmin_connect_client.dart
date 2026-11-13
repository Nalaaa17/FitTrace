import 'garmin_session.dart';

/// Interpretation of a lightweight Garmin Connect session probe (`M1-03`).
enum ProbeStatus {
  valid,
  expired,
  rateLimited,
  challengeRequired,
  networkError,
}

class SessionProbeResult {
  const SessionProbeResult({
    required this.status,
    this.statusCode,
    this.retryAfter,
    this.message,
  });

  final ProbeStatus status;
  final int? statusCode;
  final Duration? retryAfter;
  final String? message;
}

/// Abstract HTTPS client talking strictly to Garmin Connect endpoints.
abstract interface class GarminConnectClient {
  /// Lightweight probe against `/activitylist-service/...?limit=1` (`M1-03`).
  Future<SessionProbeResult> probeSession();

  /// Fetches a page of Garmin activities (50 per page by default, PRD §2.3).
  Future<List<GarminActivitySummary>> fetchActivitiesPage({
    required int start,
    int limit = 50,
  });

  /// Streams `.FIT` (or Garmin `.ZIP` wrapping `.FIT`) binary chunks (`M1-06`).
  Stream<List<int>> downloadFitStream(int garminActivityId);
}

