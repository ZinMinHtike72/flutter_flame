import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:game_test/app/app.dart";
import "package:game_test/app/di/injection_container.dart";
import "package:game_test/core/env/app_flavor.dart";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  configureDependencies(flavor: AppFlavor.current);
  runApp(const App());
}
