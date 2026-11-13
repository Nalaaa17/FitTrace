/// Result of a silent headless WebView session refresh attempt (`M1-04`).
enum RefreshOutcome {
  refreshed,
  expiredOrLoginRequired,
  challengeRequired,
  failed,
}

/// Attempts silent session cookie refresh without blocking UI (`M1-04`).
abstract interface class GarminSessionRefresher {
  Future<RefreshOutcome> attemptSilentRefresh();
}

