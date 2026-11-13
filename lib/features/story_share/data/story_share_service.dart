import 'package:flutter/services.dart';

import '../../../core/logging/app_logger.dart';

enum InstagramShareOutcome {
  launched,
  notInstalled,
  cancelled,
  failed,
}

/// Thin native bridge for `com.fittrace.app/story_share` (`PRD M4-06`, `ADR-005`).
abstract interface class StoryShareService {
  Future<bool> isInstagramInstalled();

  Future<InstagramShareOutcome> shareToInstagramStory({
    String? backgroundPath,
    String? stickerPath,
    String topColorHex = '#0A0A0A',
    String bottomColorHex = '#0A0A0A',
    String appId = 'com.fittrace.app',
  });

  Future<String> saveToGallery({
    required String filePath,
    required String displayName,
  });
}

class MethodChannelStoryShareService implements StoryShareService {
  const MethodChannelStoryShareService([
    this._channel = const MethodChannel('com.fittrace.app/story_share'),
  ]);

  final MethodChannel _channel;

  @override
  Future<bool> isInstagramInstalled() async {
    try {
      final installed =
          await _channel.invokeMethod<bool>('isInstagramInstalled');
      return installed ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException catch (error) {
      AppLogger.warn('StoryShareService', 'Instagram check failed', error);
      return false;
    }
  }

  @override
  Future<InstagramShareOutcome> shareToInstagramStory({
    String? backgroundPath,
    String? stickerPath,
    String topColorHex = '#0A0A0A',
    String bottomColorHex = '#0A0A0A',
    String appId = 'com.fittrace.app',
  }) async {
    try {
      final raw = await _channel.invokeMethod<String>(
        'shareToInstagramStory',
        <String, Object?>{
          'backgroundPath': backgroundPath,
          'stickerPath': stickerPath,
          'topColorHex': topColorHex,
          'bottomColorHex': bottomColorHex,
          'appId': appId,
        },
      );
      switch (raw) {
        case 'launched':
          return InstagramShareOutcome.launched;
        case 'not_installed':
          return InstagramShareOutcome.notInstalled;
        case 'cancelled':
          return InstagramShareOutcome.cancelled;
        default:
          return InstagramShareOutcome.failed;
      }
    } on MissingPluginException {
      return InstagramShareOutcome.notInstalled;
    } on PlatformException catch (error) {
      AppLogger.warn('StoryShareService', 'Instagram share failed', error);
      return InstagramShareOutcome.failed;
    }
  }

  @override
  Future<String> saveToGallery({
    required String filePath,
    required String displayName,
  }) async {
    final result = await _channel.invokeMethod<String>(
      'saveToGallery',
      <String, Object?>{
        'filePath': filePath,
        'displayName': displayName,
      },
    );
    return result ?? displayName;
  }
}

