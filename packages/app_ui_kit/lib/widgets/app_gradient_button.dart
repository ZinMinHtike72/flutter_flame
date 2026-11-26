import "package:app_ui_kit/theme/app_spacing.dart";
import "package:app_ui_kit/widgets/app_pressable.dart";
import "package:flutter/material.dart";

/// Shared height of the app's primary and secondary buttons.
const appButtonHeight = 60.0;
const _gradientDepth = 0.12;

/// Colour family of [AppGradientButton].
enum AppButtonTone {
  /// Brand action.
  primary,

  /// Irreversible action, such as signing out.
  destructive,
}

/// A rounded brand action with an optional left-to-right progress fill and
/// the shared press feedback.
class AppGradientButton extends StatelessWidget {
  /// Creates an action; disabled progress actions retain full contrast.
  const AppGradientButton({
    required this.onPressed,
    required this.child,
    super.key,
    this.progress,
    this.tone = AppButtonTone.primary,
  }) : assert(progress == null || (progress >= 0 && progress <= 1));

  /// Callback, or null when interaction is disabled.
  final VoidCallback? onPressed;

  /// Accessible caller-supplied content.
  final Widget child;

  /// Optional visual progress from zero to one; animation is caller-owned.
  final double? progress;

  /// Brand or destructive colours.
  final AppButtonTone tone;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final colors = tone == AppButtonTone.destructive
        ? scheme.copyWith(primary: scheme.error, onPrimary: scheme.onError)
        : scheme;
    final primary = HSLColor.fromColor(colors.primary);
    final deep = primary
        .withLightness((primary.lightness - _gradientDepth).clamp(0, 1))
        .toColor();
    final radius = BorderRadius.circular(AppSpacing.md);
    return AppPressable(
      enabled: onPressed != null,
      child: Semantics(
        button: true,
        enabled: onPressed != null,
        child: DecoratedBox(
          decoration: BoxDecoration(
            borderRadius: radius,
            boxShadow: [
              if (onPressed != null || progress != null)
                BoxShadow(
                  color: colors.primary.withValues(alpha: 0.22),
                  blurRadius: AppSpacing.lg,
                  offset: const Offset(0, AppSpacing.sm),
                ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Material(
              color: progress == null ? colors.primary : deep,
              child: InkWell(
                onTap: onPressed,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned.fill(
                      child: Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: FractionallySizedBox(
                          widthFactor: progress ?? 1,
                          heightFactor: 1,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                colors: [colors.primary, deep],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    ConstrainedBox(
                      constraints: const BoxConstraints(
                        minHeight: appButtonHeight,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        child: DefaultTextStyle.merge(
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w600,
                                color: colors.onPrimary,
                              ),
                          child: IconTheme.merge(
                            data: IconThemeData(color: colors.onPrimary),
                            child: child,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
