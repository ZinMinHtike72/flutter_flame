import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";
import "package:game_test/app/router/app_router.dart";
import "package:game_test/l10n/gen/app_localizations.dart";

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp.router(
    debugShowCheckedModeBanner: false,
    onGenerateTitle: (context) => AppLocalizations.of(context).appTitle,
    theme: LightTheme.light(),
    darkTheme: DarkTheme.dark(),
    routerConfig: AppRouter.router,
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
  );
}
