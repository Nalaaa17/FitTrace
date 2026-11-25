import 'dart:convert';
import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Manages the 256-bit local database encryption passphrase in OS Keystore /
/// Keychain (`first_unlock_this_device`).
class DatabaseEncryptionKeyStore {
  DatabaseEncryptionKeyStore([FlutterSecureStorage? storage])
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(),
              iOptions: IOSOptions(
                accessibility: KeychainAccessibility.first_unlock_this_device,
              ),
            );

  static const String _dbKeyStorageKey = 'fittrace_sqlite_key_v1';

  final FlutterSecureStorage _storage;

  Future<String> getOrCreatePassphrase() async {
    final existing = await _storage.read(key: _dbKeyStorageKey);
    if (existing != null && existing.isNotEmpty) {
      return existing;
    }
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    final generated = base64UrlEncode(bytes);
    await _storage.write(key: _dbKeyStorageKey, value: generated);
    return generated;
  }
}
