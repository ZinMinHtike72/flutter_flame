import "package:flutter/widgets.dart";

const _countDuration = Duration(milliseconds: 1100);

/// Number text that counts up from zero when first shown and rolls smoothly
/// to each new [value]. Digits are tabular so the width doesn't jitter.
/// Reduced motion shows the final value at once.
class AppCountUp extends StatelessWidget {
  /// Creates the counter.
  const AppCountUp({
    required this.value,
    required this.format,
    super.key,
    this.style,
    this.duration = _countDuration,
    this.semanticsLabel,
  });

  /// Value to show.
  final double value;

  /// Turns the in-flight value into text, such as a locale number format.
  final String Function(double value) format;

  /// Text style; tabular figures are added.
  final TextStyle? style;

  /// Time to reach [value].
  final Duration duration;

  /// Screen reader text; defaults to the formatted final value.
  final String? semanticsLabel;

  @override
  Widget build(BuildContext context) {
    final textStyle = (style ?? const TextStyle()).copyWith(
      fontFeatures: const [FontFeature.tabularFigures()],
    );
    return Semantics(
      label: semanticsLabel ?? format(value),
      excludeSemantics: true,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: MediaQuery.disableAnimationsOf(context)
            ? Duration.zero
            : duration,
        curve: Curves.easeOutCubic,
        builder: (context, current, _) => Text(
          format(current),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: textStyle,
        ),
      ),
    );
  }
}
