import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:app_ui_kit/widgets/app_card.dart";
import "package:app_ui_kit/widgets/app_float.dart";
import "package:app_ui_kit/widgets/app_gradient_button.dart";
import "package:app_ui_kit/widgets/app_icons.dart";
import "package:flutter/material.dart";

const _iconSize = 40.0;

/// Card shown when a page could not load, with a retry button.
class AppErrorCard extends StatelessWidget {
  /// Creates the card.
  const AppErrorCard({
    required this.title,
    required this.body,
    required this.retryLabel,
    required this.onRetry,
    super.key,
    this.icon = AppIcons.error,
  });

  /// Glyph above the title, such as [AppIcons.offline].
  final IconData icon;

  /// What went wrong.
  final String title;

  /// What to do.
  final String body;

  /// Retry button text.
  final String retryLabel;

  /// Retries.
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    return AppCard(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          AppFloat(
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: colors.badSoft,
                shape: BoxShape.circle,
              ),
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Icon(icon, size: _iconSize, color: colors.bad),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            title,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontWeight: FontWeight.w600,
              color: colors.textStrong,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            body,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.textMuted),
          ),
          const SizedBox(height: AppSpacing.lg),
          AppGradientButton(onPressed: onRetry, child: Text(retryLabel)),
        ],
      ),
    );
  }
}
