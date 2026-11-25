import 'package:flutter/material.dart';

import '../../features/activity_detail/presentation/activity_detail_screen.dart';
import '../../features/onboarding/presentation/splash_screen.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../features/shoes/presentation/shoe_management_screen.dart';

/// Centralized route definitions and `fittrace://` deep-link resolver.
class AppRoutes {
  AppRoutes._();

  static const String root = '/';
  static const String settings = '/settings';
  static const String shoes = '/shoes';

  static String activityDetail(int activityId) => '/activity/$activityId';
}

class AppRouter {
  AppRouter._();

  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    final rawName = settings.name;
    if (rawName == null || rawName.isEmpty || rawName == AppRoutes.root) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SplashScreen(),
      );
    }

    final uri = Uri.tryParse(rawName);
    if (uri == null) return null;

    // Support both `/shoes` and `fittrace://shoes` / `fittrace://activity/42`.
    final path = uri.scheme == 'fittrace'
        ? '/${uri.host}${uri.path}'
        : uri.path;

    if (path == AppRoutes.shoes) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const ShoeManagementScreen(),
      );
    }

    if (path == AppRoutes.settings) {
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (_) => const SettingsScreen(),
      );
    }

    final segments = uri.scheme == 'fittrace'
        ? <String>[uri.host, ...uri.pathSegments]
        : uri.pathSegments;
    if (segments.length == 2 && segments.first == 'activity') {
      final activityId = int.tryParse(segments[1]);
      if (activityId != null) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (_) => ActivityDetailScreen(activityId: activityId),
        );
      }
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (_) => const SplashScreen(),
    );
  }
}
