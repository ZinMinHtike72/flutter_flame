import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";

/// A connected activity rail sized to its content, including scaled text.
class AppTimelineEntry extends StatelessWidget {
  const AppTimelineEntry({
    required this.color,
    required this.icon,
    required this.child,
    required this.isLast,
    super.key,
  });
  final Color color;
  final IconData icon;
  final Widget child;
  final bool isLast;
  @override
  Widget build(BuildContext context) => IntrinsicHeight(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SizedBox(
          width: 32,
          child: Column(
            children: [
              DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withValues(alpha: 0.12),
                  border: Border.all(color: color.withValues(alpha: 0.22)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  child: Icon(icon, size: 14, color: color),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Center(
                    child: SizedBox(
                      width: 2,
                      height: double.infinity,
                      child: ColoredBox(color: color.withValues(alpha: 0.15)),
                    ),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.md),
            child: child,
          ),
        ),
      ],
    ),
  );
}
