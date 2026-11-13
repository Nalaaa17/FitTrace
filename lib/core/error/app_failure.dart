/// Typed domain failures shared across features.
sealed class AppFailure implements Exception {
  const AppFailure(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => '$runtimeType: $message';
}

final class DatabaseFailure extends AppFailure {
  const DatabaseFailure(super.message, [super.cause]);
}

final class ImportFailure extends AppFailure {
  const ImportFailure(super.message, [super.cause]);
}

final class ParseFailure extends AppFailure {
  const ParseFailure(super.message, [super.cause]);
}

final class SyncAuthFailure extends AppFailure {
  const SyncAuthFailure(super.message, [super.cause]);
}

final class RateLimitFailure extends AppFailure {
  const RateLimitFailure(super.message, [super.cause]);
}

final class StorageFullFailure extends AppFailure {
  const StorageFullFailure(super.message, [super.cause]);
}

