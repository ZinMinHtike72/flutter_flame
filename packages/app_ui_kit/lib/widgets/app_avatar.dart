import "package:app_ui_kit/theme/app_colors_extension.dart";
import "package:flutter/material.dart";

const _ringPeriod = Duration(seconds: 6);

/// Round avatar showing initials on a brand gradient, with an optional
/// slowly rotating gradient ring. Reduced motion keeps the ring still.
class AppAvatar extends StatefulWidget {
  /// Creates an avatar for [name].
  const AppAvatar({
    required this.name,
    super.key,
    this.size = 48,
    this.showRing = false,
  });

  /// Person's name; up to two initials are shown.
  final String name;

  /// Outer diameter.
  final double size;

  /// Whether to draw the rotating ring.
  final bool showRing;

  /// Up to two uppercase initials from [name], Unicode-safe.
  static String initialsOf(String name) {
    final words = name.trim().split(RegExp(r"\s+")).where((w) => w.isNotEmpty);
    return words
        .take(2)
        .map((word) => word.characters.first.toUpperCase())
        .join();
  }

  @override
  State<AppAvatar> createState() => _AppAvatarState();
}

class _AppAvatarState extends State<AppAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ring = AnimationController(
    vsync: this,
    duration: _ringPeriod,
  );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncRing();
  }

  @override
  void didUpdateWidget(covariant AppAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    _syncRing();
  }

  void _syncRing() {
    if (!widget.showRing || MediaQuery.disableAnimationsOf(context)) {
      _ring.stop();
    } else if (!_ring.isAnimating) {
      _ring.repeat();
    }
  }

  @override
  void dispose() {
    _ring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final primary = HSLColor.fromColor(colors.primary);
    final accent = primary.withHue((primary.hue + 40) % 360).toColor();
    final deep = primary
        .withLightness((primary.lightness - 0.14).clamp(0, 1))
        .toColor();
    final ringWidth = widget.showRing ? widget.size * 0.05 : 0.0;
    final gap = widget.showRing ? widget.size * 0.04 : 0.0;
    final face = DecoratedBox(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, context.appColors.avatarEnd],
        ),
      ),
      child: Center(
        child: Text(
          AppAvatar.initialsOf(widget.name),
          style: theme.textTheme.titleLarge?.copyWith(
            color: colors.onPrimary,
            fontWeight: FontWeight.w700,
            fontSize: widget.size * 0.34,
            height: 1,
          ),
        ),
      ),
    );
    return Semantics(
      image: true,
      label: widget.name,
      child: SizedBox.square(
        dimension: widget.size,
        child: Stack(
          fit: StackFit.expand,
          children: [
            if (widget.showRing)
              RotationTransition(
                turns: _ring,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: SweepGradient(
                      colors: [colors.primary, accent, deep, colors.primary],
                    ),
                  ),
                ),
              ),
            Padding(
              padding: EdgeInsets.all(ringWidth),
              child: DecoratedBox(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.showRing ? colors.surface : null,
                ),
                child: Padding(padding: EdgeInsets.all(gap), child: face),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
