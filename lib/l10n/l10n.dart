import "package:flutter/widgets.dart";
import "package:game_test/l10n/gen/app_localizations.dart";

extension AppLocalizationsContext on BuildContext {
  AppLocalizations get l10n => AppLocalizations.of(this);
}
