import "package:app_ui_kit/theme/app_spacing.dart";
import "package:flutter/material.dart";

const _sheetMaxWidth = 640.0;
const _sheetHeightFraction = 0.85;
const _handleWidth = 32.0;
const _handleHeight = 4.0;

/// Native modal sheet with an accessible barrier, drag handle, and safe padding.
/// Its surface follows the live theme, so a theme change made from inside the
/// sheet repaints it correctly.
abstract final class AppBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required WidgetBuilder builder,
    bool scrollable = true,
    Color? surfaceColor,
    AnimationStyle? animationStyle,
  }) => showModalBottomSheet<T>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    elevation: 0,
    constraints: const BoxConstraints(maxWidth: _sheetMaxWidth),
    sheetAnimationStyle: MediaQuery.disableAnimationsOf(context)
        ? AnimationStyle.noAnimation
        : animationStyle,
    builder: (context) => _SheetSurface(
      color: surfaceColor,
      child: SafeArea(
        top: false,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.sizeOf(context).height * _sheetHeightFraction,
          ),
          child: scrollable
              ? SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: builder(context),
                )
              : Padding(
                  padding: const EdgeInsets.fromLTRB(
                    AppSpacing.lg,
                    0,
                    AppSpacing.lg,
                    AppSpacing.lg,
                  ),
                  child: builder(context),
                ),
        ),
      ),
    ),
  );
}

class _SheetSurface extends StatelessWidget {
  const _SheetSurface({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Material(
      color: color ?? colors.surface,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppSpacing.xl),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.only(
              top: AppSpacing.md - 4,
              bottom: AppSpacing.md,
            ),
            child: Center(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  color: colors.onSurfaceVariant.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(_handleHeight),
                ),
                child: const SizedBox(
                  width: _handleWidth,
                  height: _handleHeight,
                ),
              ),
            ),
          ),
          Flexible(child: child),
        ],
      ),
    );
  }
}
