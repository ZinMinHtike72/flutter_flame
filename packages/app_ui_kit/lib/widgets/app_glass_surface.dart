import "dart:ui";

import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";

const _blurSigma = 24.0;

/// Frosted, translucent card that lets a background glow show through.
class AppGlassSurface extends StatelessWidget {
  /// Creates a glass surface.
  const AppGlassSurface({
    required this.child,
    super.key,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
  });

  /// Card content.
  final Widget child;

  /// Inner padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final isDark = theme.brightness == Brightness.dark;
    final radius = BorderRadius.circular(AppSpacing.lg + AppSpacing.xs);
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: radius,
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: isDark ? 0.18 : 0.10),
            blurRadius: AppSpacing.xl + AppSpacing.md,
            offset: const Offset(0, AppSpacing.md),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: _blurSigma, sigmaY: _blurSigma),
          child: DecoratedBox(
            decoration: BoxDecoration(
              borderRadius: radius,
              color: colors.surface.withValues(alpha: isDark ? 0.62 : 0.74),
              border: Border.all(
                color: isDark
                    ? colors.onSurface.withValues(alpha: 0.10)
                    : Colors.white.withValues(alpha: 0.8),
              ),
            ),
            child: Padding(padding: padding, child: child),
          ),
        ),
      ),
    );
  }
}
