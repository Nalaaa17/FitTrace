// ignore: unused_import
import 'package:intl/intl.dart' as intl;

import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'FitTrace';

  @override
  String get feedTitle => 'Activities';

  @override
  String get statsTitle => 'Statistics';

  @override
  String get settingsTitle => 'Settings';

  @override
  String get shoesTitle => 'Running Shoe Tracker';

  @override
  String get weeklyTargetTitle => 'THIS WEEK\'S TARGET';

  @override
  String get retryButton => 'Retry';

  @override
  String get cancelButton => 'Cancel';

  @override
  String get saveButton => 'Save';

  @override
  String get deleteButton => 'Delete';
}
