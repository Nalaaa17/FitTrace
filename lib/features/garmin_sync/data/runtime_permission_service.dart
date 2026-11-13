import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../../core/logging/app_logger.dart';

class RuntimePermissionsSnapshot {
  const RuntimePermissionsSnapshot({
    required this.locationGranted,
    required this.notificationGranted,
    required this.storageGranted,
  });

  final bool locationGranted;
  final bool notificationGranted;
  final bool storageGranted;
}

/// Non-blocking runtime permission requester following PRD §2.2:
/// Location, Notification, and Storage (Android <= 12) remain optional.
abstract interface class RuntimePermissionService {
  Future<RuntimePermissionsSnapshot> checkAll();
  Future<RuntimePermissionsSnapshot> requestOptionalPermissions();
}

class DeviceRuntimePermissionService implements RuntimePermissionService {
  const DeviceRuntimePermissionService();

  @override
  Future<RuntimePermissionsSnapshot> checkAll() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return const RuntimePermissionsSnapshot(
        locationGranted: true,
        notificationGranted: true,
        storageGranted: true,
      );
    }

    try {
      final location = await Permission.locationWhenInUse.status;
      final notification = await Permission.notification.status;
      final storage = Platform.isAndroid
          ? await Permission.storage.status
          : PermissionStatus.granted;

      return RuntimePermissionsSnapshot(
        locationGranted: location.isGranted,
        notificationGranted: notification.isGranted,
        storageGranted: storage.isGranted,
      );
    } on MissingPluginException {
      return const RuntimePermissionsSnapshot(
        locationGranted: false,
        notificationGranted: false,
        storageGranted: false,
      );
    } on Object catch (error) {
      AppLogger.warn('RuntimePermissions', 'Permission status check failed', error);
      return const RuntimePermissionsSnapshot(
        locationGranted: false,
        notificationGranted: false,
        storageGranted: false,
      );
    }
  }

  @override
  Future<RuntimePermissionsSnapshot> requestOptionalPermissions() async {
    if (kIsWeb || !(Platform.isAndroid || Platform.isIOS)) {
      return const RuntimePermissionsSnapshot(
        locationGranted: true,
        notificationGranted: true,
        storageGranted: true,
      );
    }

    try {
      final results = await <Permission>[
        Permission.locationWhenInUse,
        Permission.notification,
        if (Platform.isAndroid) Permission.storage,
      ].request();

      return RuntimePermissionsSnapshot(
        locationGranted: results[Permission.locationWhenInUse]?.isGranted ?? false,
        notificationGranted: results[Permission.notification]?.isGranted ?? false,
        storageGranted: Platform.isAndroid
            ? (results[Permission.storage]?.isGranted ?? false)
            : true,
      );
    } on MissingPluginException {
      return const RuntimePermissionsSnapshot(
        locationGranted: false,
        notificationGranted: false,
        storageGranted: false,
      );
    } on Object catch (error) {
      AppLogger.warn('RuntimePermissions', 'Permission request failed', error);
      return checkAll();
    }
  }
}

