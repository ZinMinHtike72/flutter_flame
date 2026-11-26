import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:app_ui_kit/theme/app_spacing.dart";
import "package:app_ui_kit/widgets/app_icons.dart";
import "package:app_ui_kit/widgets/app_round_icon_button.dart";
import "package:flutter/material.dart";
import "package:flutter/services.dart";

const _toolbarHeight = 60.0;
const _leadingGap = 10.0;
const _roundButton = 40.0;
const _actionGap = 8.0;

/// Pinned page app bar on the canvas colour, built on Flutter's
/// [SliverAppBar]: optional back button (or any [leading]), a title with an
/// optional subtitle, round [actions], and an optional [bottom] that stays
/// pinned too, such as a date strip. Use it as the first sliver of a
/// [CustomScrollView].
class AppSliverAppBar extends StatelessWidget {
  /// Creates the app bar.
  const AppSliverAppBar({
    super.key,
    this.title,
    this.subtitle,
    this.titleWidget,
    this.onBack,
    this.backLabel,
    this.leading,
    this.leadingSize = _roundButton,
    this.actions = const [],
    this.bottom,
    this.bottomHeight = 0,
    this.toolbarHeight = _toolbarHeight,
  });

  /// Page title.
  final String? title;

  /// Small text under [title].
  final String? subtitle;

  /// Custom title in place of [title] and [subtitle].
  final Widget? titleWidget;

  /// Shows a round back button that calls this.
  final VoidCallback? onBack;

  /// Back button text for screen readers.
  final String? backLabel;

  /// Custom leading widget, used when [onBack] is null.
  final Widget? leading;

  /// Width of [leading].
  final double leadingSize;

  /// Widgets at the end, such as round buttons or a pill.
  final List<Widget> actions;

  /// Content pinned under the toolbar.
  final Widget? bottom;

  /// Height of [bottom].
  final double bottomHeight;

  /// Toolbar height.
  final double toolbarHeight;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = context.appColors;
    final back = onBack;
    final leadingWidget = back != null
        ? AppRoundIconButton(
            icon: AppIcons.chevronBack,
            label: backLabel ?? "",
            onPressed: back,
          )
        : leading;
    final compact = back != null;
    final titleStyle =
        (compact ? theme.textTheme.titleSmall : theme.textTheme.titleMedium)
            ?.copyWith(fontWeight: FontWeight.w600, color: colors.textStrong);
    final bottomWidget = bottom;
    return SliverAppBar(
      pinned: true,
      centerTitle: false,
      automaticallyImplyLeading: false,
      backgroundColor: colors.canvas,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: toolbarHeight,
      systemOverlayStyle: theme.brightness == Brightness.dark
          ? SystemUiOverlayStyle.light
          : SystemUiOverlayStyle.dark,
      leadingWidth: leadingWidget == null
          ? null
          : AppSpacing.md + leadingSize + _leadingGap,
      leading: leadingWidget == null
          ? null
          : Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: _leadingGap,
              ),
              child: Center(child: leadingWidget),
            ),
      titleSpacing: leadingWidget == null ? AppSpacing.md : 0,
      title:
          titleWidget ??
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title ?? "",
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: titleStyle,
              ),
              if (subtitle != null)
                Text(
                  subtitle!,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colors.textMuted,
                  ),
                ),
            ],
          ),
      actions: [
        for (final action in actions) ...[
          Center(child: action),
          const SizedBox(width: _actionGap),
        ],
        const SizedBox(width: AppSpacing.md - _actionGap),
      ],
      bottom: bottomWidget == null
          ? null
          : PreferredSize(
              preferredSize: Size.fromHeight(bottomHeight),
              child: SizedBox(height: bottomHeight, child: bottomWidget),
            ),
    );
  }
}
