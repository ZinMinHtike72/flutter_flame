import "package:flutter/services.dart";

/// Build flavor selected with `--flavor development|production`.
enum AppFlavor {
  development,
  production;

  /// The flavor this binary was built with.
  static AppFlavor get current => switch (appFlavor) {
    "development" => AppFlavor.development,
    "production" => AppFlavor.production,
    _ => throw StateError(
      "Unknown flavor '$appFlavor'. Run with --flavor development|production.",
    ),
  };
}
