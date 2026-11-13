import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';

import '../../../core/logging/app_logger.dart';

/// Bridges Android `ACTION_SEND` / `ACTION_SEND_MULTIPLE` `.FIT` intents
/// into Flutter (PRD M1-08).
class AndroidShareIntentBridge {
  AndroidShareIntentBridge();

  static const MethodChannel _methodChannel =
      MethodChannel('com.fittrace.app/share_intent');
  static const EventChannel _eventChannel =
      EventChannel('com.fittrace.app/share_intent_events');

  Future<List<String>> getInitialSharedFiles() async {
    if (!Platform.isAndroid) return const <String>[];
    try {
      final raw = await _methodChannel.invokeListMethod<String>(
        'getInitialSharedFiles',
      );
      return raw ?? const <String>[];
    } on PlatformException catch (e) {
      AppLogger.warn('ShareIntentBridge', 'Failed reading initial share', e);
      return const <String>[];
    } on MissingPluginException {
      return const <String>[];
    }
  }

  Stream<List<String>> watchSharedFiles() {
    if (!Platform.isAndroid) return const Stream<List<String>>.empty();
    return _eventChannel.receiveBroadcastStream().map((dynamic event) {
      if (event is List) {
        return event.whereType<String>().toList(growable: false);
      }
      return const <String>[];
    });
  }
}

