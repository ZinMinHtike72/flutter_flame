// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Yum Yum Kitchen';

  @override
  String get homeTitle => 'Game starter';

  @override
  String get homeDescription =>
      'Your Flame canvas is ready. Add your first game feature under lib/features.';

  @override
  String get notFoundMessage => 'This page is unavailable.';
}
