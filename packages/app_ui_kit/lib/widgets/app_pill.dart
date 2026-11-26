import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:flutter/material.dart";

const _horizontal = 10.0;
const _vertical = 3.0;
const _radius = 999.0;

/// Colour of an [AppPill].
enum AppPillTone { good, bad, warn, info, muted }

/// Small rounded label on a tinted background, such as a class or change.
class AppPill extends StatelessWidget {
  /// Creates the pill.
  const AppPill({required this.label, super.key, this.tone = AppPillTone.info});

  /// Text.
  final String label;

  /// Colour pair.
  final AppPillTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final primary = Theme.of(context).colorScheme.primary;
    final (background, foreground) = switch (tone) {
      AppPillTone.good => (colors.goodSoft, colors.good),
      AppPillTone.bad => (colors.badSoft, colors.bad),
      AppPillTone.warn => (colors.warnSoft, colors.warn),
      AppPillTone.info => (colors.primarySoft, primary),
      AppPillTone.muted => (colors.track, colors.textMuted),
    };
    return DecoratedBox(
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(_radius),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: _horizontal,
          vertical: _vertical,
        ),
        child: Text(
          label,
          maxLines: 1,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: foreground,
          ),
        ),
      ),
    );
  }
}
