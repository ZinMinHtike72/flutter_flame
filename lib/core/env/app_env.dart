import "package:envied/envied.dart";
import "package:game_test/core/env/app_flavor.dart";

part "app_env.g.dart";

/// Per-flavor configuration read from `.env.development` / `.env.production`
/// at build time. Run `make codegen` after editing either file.
@Envied(path: ".env.development", name: "DevelopmentEnv", obfuscate: true)
@Envied(path: ".env.production", name: "ProductionEnv", obfuscate: true)
abstract final class AppEnv {
  /// Returns the configuration for [flavor].
  factory AppEnv(AppFlavor flavor) => switch (flavor) {
    AppFlavor.development => _DevelopmentEnv(),
    AppFlavor.production => _ProductionEnv(),
  };

  /// Trusted HTTPS API origin.
  @EnviedField(varName: "API_BASE_URL")
  abstract final String apiBaseUrl;
}
