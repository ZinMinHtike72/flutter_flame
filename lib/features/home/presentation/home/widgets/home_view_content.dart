import "package:flutter/widgets.dart";
import "package:game_test/app/di/injection_container.dart";
import "package:game_test/core/env/app_flavor.dart";
import "package:yumyum_kitchen/yumyum_kitchen.dart";

class HomeViewContent extends StatelessWidget {
  const HomeViewContent({super.key});

  /// `--dart-define=SHOW_HIT_BOXES=true` paints hit boxes in development.
  static const _showHitBoxes = bool.fromEnvironment("SHOW_HIT_BOXES");

  @override
  Widget build(BuildContext context) => YumYumKitchenScreen(
    embedded: false,
    showHitBoxes: _showHitBoxes && getIt<AppFlavor>() == AppFlavor.development,
  );
}
