import "package:app_ui_kit/widgets/app_pressable.dart";
import "package:flutter/material.dart" show Icons;
import "package:flutter/widgets.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:yumyum_kitchen/l10n/gen/kitchen_strings.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";

const ink = Color(0xFF3A2416);
const cream = Color(0xFFFFF1D7);
const gold = Color(0xFFFFCB69);
const paprika = Color(0xFFB33326);

// Claymorphism palette: warm, soft pastels that read as painted clay.
const clayCream = Color(0xFFFFF0D9);
const clayButter = Color(0xFFFFC55A);
const clayTomato = Color(0xFFFF7E5F);
const clayMint = Color(0xFF8ED7B3);
const clayShadow = Color(0xFF5A3414);
const imageRoot = "packages/yumyum_kitchen/assets/images/";

extension KitchenContext on BuildContext {
  KitchenStrings get kitchen => KitchenStrings.of(this);
  void act(ActionType action, [int index = 0]) =>
      read<KitchenBloc>().add(KitchenAction(action, index));
}

String productName(KitchenStrings s, NoodleProduct p) =>
    [s.original, s.xcite, s.ultra][p.index];
String chapter(KitchenStrings s, int level) =>
    [s.opening, s.rush, s.closing][(level - 1) ~/ 4];
String goalText(KitchenStrings s, Shift shift) =>
    "${shift.target} ${shift.goal == Goal.coins ? s.coins : s.customers}";
TextStyle marketText(double size, {Color color = cream, bool bold = false}) =>
    TextStyle(
      fontFamily: "Poppins",
      fontFamilyFallback: const ["NotoSansMyanmar"],
      color: color,
      fontSize: size,
      height: 1.2,
      fontWeight: bold ? FontWeight.w800 : FontWeight.w500,
      decoration: TextDecoration.none,
    );

/// A soft, puffy clay surface (claymorphism): a rounded body lit from the
/// top left, a glossy highlight along the top, a gentle shade along the
/// bottom, a light rim, and a soft drop shadow in the clay's own deep tone.
class ClaySurface extends StatelessWidget {
  const ClaySurface({
    required this.child,
    super.key,
    this.color = clayCream,
    this.radius = 20,
    this.depth = 1,
    this.padding = EdgeInsets.zero,
  });

  final Widget child;
  final Color color;
  final double radius;

  /// Shadow size: 1 for buttons and panels, less for small chips.
  final double depth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final shape = BorderRadius.circular(radius);
    final light = Color.lerp(color, const Color(0xFFFFFFFF), .38)!;
    final deep = Color.lerp(color, clayShadow, .28)!;
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: shape,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [light, color, deep],
          stops: const [0, .5, 1],
        ),
        border: Border.all(color: light, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Color.lerp(color, clayShadow, .7)!.withValues(alpha: .55),
            offset: Offset(0, 7 * depth),
            blurRadius: 16 * depth,
          ),
          BoxShadow(
            color: const Color(0x33000000),
            offset: Offset(0, 2 * depth),
            blurRadius: 3 * depth,
          ),
        ],
      ),
      child: Stack(
        children: [
          // Inner shade along the bottom edge.
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: shape,
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0x00000000),
                    Color(0x00000000),
                    Color(0x1F3A1A00),
                  ],
                  stops: [0, .6, 1],
                ),
              ),
            ),
          ),
          // Gloss along the top, inset from the rim.
          Positioned(
            left: radius * .35,
            right: radius * .35,
            top: 3,
            height: radius * .9,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(radius),
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x8CFFFFFF), Color(0x00FFFFFF)],
                ),
              ),
            ),
          ),
          Padding(padding: padding, child: child),
        ],
      ),
    );
  }
}

/// The game's button: a clay pill. [primary] is butter yellow, the rest
/// cream; [danger] is tomato. Presses squash it (AppPressable).
class MarketButton extends StatelessWidget {
  const MarketButton(
    this.label,
    this.onTap, {
    super.key,
    this.primary = false,
    this.danger = false,
    this.icon,
    this.compact = false,
    this.enabled = true,
  });
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final bool danger;
  final IconData? icon;
  final bool compact;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final color = danger
        ? clayTomato
        : primary
        ? clayButter
        : clayCream;
    return Semantics(
      button: true,
      enabled: enabled,
      onTap: enabled ? onTap : null,
      label: label,
      child: ExcludeSemantics(
        child: AppPressable(
          child: GestureDetector(
            onTap: enabled ? onTap : null,
            behavior: HitTestBehavior.opaque,
            child: Opacity(
              opacity: enabled ? 1 : .55,
              child: ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: ClaySurface(
                  color: color,
                  radius: compact ? 16 : 20,
                  depth: compact ? .7 : 1,
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 11 : 20,
                    vertical: 9,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) Icon(icon, color: ink, size: 20),
                      if (!compact) ...[
                        if (icon != null) const SizedBox(width: 7),
                        Flexible(
                          child: Text(
                            label,
                            textAlign: TextAlign.center,
                            style: marketText(15, color: ink, bold: true),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class MarketBackdrop extends StatelessWidget {
  const MarketBackdrop({required this.child, super.key, this.entrance = false});
  final Widget child;
  final bool entrance;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      Image.asset("${imageRoot}entrance.webp", fit: BoxFit.cover),
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: entrance
                ? const [
                    Color(0xF20D2628),
                    Color(0xC2132929),
                    Color(0x00102929),
                  ]
                : const [Color(0xEA122D2C), Color(0xDA152824)],
            stops: entrance ? const [0, .38, .75] : null,
          ),
        ),
      ),
      SafeStage(child: child),
      if (entrance) const _AwningLift(),
    ],
  );
}

/// The striped awning lifts away to reveal the entrance (600 ms,
/// easeOutCubic). Decorative only: it never takes taps, and reduced motion
/// shows the entrance straight away.
class _AwningLift extends StatelessWidget {
  const _AwningLift();
  static const duration = Duration(milliseconds: 600);
  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : duration,
      curve: Curves.easeOutCubic,
      builder: (context, lift, child) => lift >= 1
          ? const SizedBox.shrink()
          : Align(
              alignment: Alignment.topCenter,
              child: FractionalTranslation(
                translation: Offset(0, -lift),
                child: child,
              ),
            ),
      child: FractionallySizedBox(
        widthFactor: 1,
        heightFactor: .62,
        child: Image.asset("${imageRoot}awning.webp", fit: BoxFit.cover),
      ),
    ),
  );
}

/// Insets [child] to the safe stage: system view padding plus the 24 px
/// gesture-edge margin on every side. Backgrounds stay edge to edge.
class SafeStage extends StatelessWidget {
  const SafeStage({required this.child, super.key});
  final Widget child;
  static const margin = 24.0;
  @override
  Widget build(BuildContext context) => Padding(
    padding: MediaQuery.viewPaddingOf(context) + const EdgeInsets.all(margin),
    child: child,
  );
}

class MarketHeader extends StatelessWidget {
  const MarketHeader(this.title, {super.key, this.trailing, this.onBack});
  final String title;
  final Widget? trailing;
  final VoidCallback? onBack;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      MarketButton(
        context.kitchen.back,
        onBack ?? () => context.act(ActionType.back),
        icon: Icons.arrow_back_rounded,
        compact: true,
      ),
      const SizedBox(width: 12),
      Expanded(child: Text(title, style: marketText(24, bold: true))),
      ?trailing,
    ],
  );
}

class MarketPanel extends StatelessWidget {
  const MarketPanel(this.child, {super.key});
  final Widget child;
  @override
  Widget build(BuildContext context) => ClaySurface(
    radius: 28,
    depth: 1.3,
    padding: const EdgeInsets.all(18),
    child: child,
  );
}

/// While [blocking], an opaque layer under [child] absorbs every pointer that
/// misses the overlay's own controls, so scrim taps never reach the game.
class ScrimGuard extends StatelessWidget {
  const ScrimGuard({required this.blocking, required this.child, super.key});
  final bool blocking;
  final Widget child;
  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: [
      if (blocking)
        const Listener(
          behavior: HitTestBehavior.opaque,
          child: SizedBox.expand(),
        ),
      child,
    ],
  );
}
