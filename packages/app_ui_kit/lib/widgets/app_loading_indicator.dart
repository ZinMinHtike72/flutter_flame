import "package:flutter/material.dart";

/// Sized indeterminate progress with a caller-localized announcement.
class AppLoadingIndicator extends StatelessWidget {
  /// Creates an indicator with optional size and color overrides.
  const AppLoadingIndicator({
    super.key,
    this.size = 20,
    this.strokeWidth = 2,
    this.color,
    this.semanticsLabel,
  });

  /// Square side length.
  final double size;

  /// Progress stroke thickness.
  final double strokeWidth;

  /// Optional foreground override.
  final Color? color;

  /// Caller-localized progress description.
  final String? semanticsLabel;
  @override
  Widget build(BuildContext context) => SizedBox.square(
    dimension: size,
    child: CircularProgressIndicator(
      strokeWidth: strokeWidth,
      color: color,
      semanticsLabel: semanticsLabel,
    ),
  );
}
