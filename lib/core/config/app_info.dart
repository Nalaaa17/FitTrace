/// Single source of truth for application version metadata (`pubspec.yaml`).
class AppInfo {
  AppInfo._();

  static const String version = '1.0.2';
  static const int buildNumber = 3;
  static const String versionLabel = 'FitTrace v$version';
}
