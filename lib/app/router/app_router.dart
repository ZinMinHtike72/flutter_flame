import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/widgets.dart";
import "package:game_test/app/router/route_path.dart";
import "package:game_test/features/home/presentation/home/view/home_screen.dart";
import "package:game_test/l10n/l10n.dart";
import "package:go_router/go_router.dart";

abstract final class AppRouter {
  static final GoRouter router = GoRouter(
    routes: [
      GoRoute(
        name: RouterPath.I.home.name,
        path: RouterPath.I.home.fullPath,
        builder: (context, state) => const HomeScreen(),
      ),
    ],
    errorBuilder: (context, state) => const _DetailUnavailablePage(),
  );
}

class _DetailUnavailablePage extends StatelessWidget {
  const _DetailUnavailablePage();

  @override
  Widget build(BuildContext context) => AppScaffold(
    body: SafeArea(child: Center(child: Text(context.l10n.notFoundMessage))),
  );
}
