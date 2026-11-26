import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/material.dart";

/// Shared native-sheet heading with a single clear dismissal action.
class AppSheetHeader extends StatelessWidget {
  const AppSheetHeader({
    required this.icon,
    required this.title,
    required this.closeLabel,
    required this.onClose,
    super.key,
    this.subtitle,
    this.compact = false,
  });
  final bool compact;
  final IconData icon;
  final String title;
  final String? subtitle;
  final String closeLabel;
  final VoidCallback onClose;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Row(
        children: [
          if (!compact || MediaQuery.textScalerOf(context).scale(1) <= 1.4)
            AppAnimatedBadge(icon: icon),
          if (compact) ...[
            if (MediaQuery.textScalerOf(context).scale(1) <= 1.4)
              const SizedBox(width: AppSpacing.md),
            Expanded(child: _title(context)),
          ] else
            const Spacer(),
          AppIconButton(
            icon: AppIcons.close,
            tooltip: closeLabel,
            onPressed: onClose,
          ),
        ],
      ),
      if (!compact) ...[const SizedBox(height: AppSpacing.md), _title(context)],
      if (subtitle != null) ...[
        const SizedBox(height: AppSpacing.sm),
        Text(
          subtitle!,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    ],
  );
  Widget _title(BuildContext context) => Text(
    title,
    style: Theme.of(
      context,
    ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
  );
}

/// A one-shot spring reveal; reduced motion displays its resting state.
class AppAnimatedBadge extends StatelessWidget {
  const AppAnimatedBadge({required this.icon, super.key});
  final IconData icon;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final badge = DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colors.primary.withValues(alpha: 0.15),
            colors.primary.withValues(alpha: 0.035),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.md),
        border: Border.all(color: colors.primary.withValues(alpha: 0.09)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Icon(icon, color: colors.primary, size: AppSpacing.lg),
      ),
    );
    if (MediaQuery.disableAnimationsOf(context)) {
      return badge;
    }
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutBack,
      child: badge,
      builder: (context, value, child) => Transform.rotate(
        angle: (1 - value) * -0.12,
        child: Transform.scale(scale: 0.85 + value * 0.15, child: child),
      ),
    );
  }
}
