import "package:app_ui_kit/widgets/app_pressable.dart";
import "package:flutter/material.dart" show Icons;
import "package:flutter/widgets.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:yumyum_kitchen/l10n/gen/kitchen_strings.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";

const ink = Color(0xFF132E2E);
const cream = Color(0xFFFFF1D7);
const gold = Color(0xFFFFCB69);
const paprika = Color(0xFFB33326);
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

class MarketButton extends StatelessWidget {
  const MarketButton(
    this.label,
    this.onTap, {
    super.key,
    this.primary = false,
    this.icon,
    this.compact = false,
    this.enabled = true,
  });
  final String label;
  final VoidCallback onTap;
  final bool primary;
  final IconData? icon;
  final bool compact;
  final bool enabled;
  @override
  Widget build(BuildContext context) {
    final fg = primary ? ink : cream;
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
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: primary ? gold : const Color(0xEE263D38),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: primary
                          ? const Color(0xFFFFDF95)
                          : const Color(0x887D9B8A),
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 19,
                      vertical: 8,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (icon != null) Icon(icon, color: fg, size: 20),
                        if (!compact) ...[
                          if (icon != null) const SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              label,
                              textAlign: TextAlign.center,
                              style: marketText(15, color: fg, bold: true),
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
      child,
    ],
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: cream,
      borderRadius: BorderRadius.circular(20),
      border: Border.all(color: const Color(0xFFE1B46C), width: 2),
    ),
    child: Padding(padding: const EdgeInsets.all(15), child: child),
  );
}
