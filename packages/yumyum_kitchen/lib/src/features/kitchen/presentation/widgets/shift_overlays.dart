import "package:app_ui_kit/widgets/app_count_up.dart";
import "package:flutter/material.dart" show Icons;
import "package:flutter/widgets.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/progress.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_style.dart";

class ShiftHud extends StatelessWidget {
  const ShiftHud(this.run, {super.key});
  final KitchenRun run;
  @override
  Widget build(BuildContext context) {
    final s = context.kitchen;
    return Stack(
      children: [
        Positioned.fill(
          child: SafeStage(
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 48,
                child: Row(
                  children: [
                    _HudStat(
                      run.shift.goal == Goal.coins
                          ? Icons.monetization_on_rounded
                          : Icons.people_alt_rounded,
                      "${run.progress}/${run.shift.target}",
                      s.goal,
                    ),
                    Expanded(
                      child: run.guide == Guide.done
                          ? const SizedBox.shrink()
                          : IgnorePointer(
                              child: Center(
                                child: FittedBox(
                                  child: _HudStat(
                                    Icons.touch_app_rounded,
                                    [
                                      s.guidePack,
                                      s.guideWait,
                                      s.guidePot,
                                      s.guideServe,
                                    ][run.guide.index],
                                    s.tutorial,
                                  ),
                                ),
                              ),
                            ),
                    ),
                    _HudStat(
                      Icons.local_fire_department_rounded,
                      "×${(run.quarterMultiplier / 4).toStringAsFixed(2)}",
                      s.combo,
                    ),
                    const SizedBox(width: 4),
                    _HudStat(
                      Icons.toll_rounded,
                      "${run.coins}",
                      s.coins,
                      count: run.coins,
                    ),
                    const SizedBox(width: 4),
                    _HudStat(
                      Icons.timer_outlined,
                      "${run.secondsLeft ~/ 60}:${(run.secondsLeft % 60).toString().padLeft(2, "0")}",
                      s.clock,
                    ),
                    const SizedBox(width: 5),
                    MarketButton(
                      s.pause,
                      () => context.act(ActionType.pause),
                      icon: Icons.pause_rounded,
                      compact: true,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _HudStat extends StatelessWidget {
  const _HudStat(this.icon, this.value, this.label, {this.count});
  final IconData icon;
  final String value;
  final String label;

  /// When set, the number counts up to it (coins after a serve).
  final int? count;
  @override
  Widget build(BuildContext context) => Semantics(
    label: "$label $value",
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xF020342F),
        border: Border.all(color: const Color(0xFFA38C5E)),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: gold, size: 18),
            const SizedBox(width: 4),
            if (count case final target?)
              AppCountUp(
                value: target.toDouble(),
                format: (v) => "${v.round()}",
                duration: const Duration(milliseconds: 400),
                style: marketText(15, bold: true),
              )
            else
              Text(value, style: marketText(15, bold: true)),
          ],
        ),
      ),
    ),
  );
}

class PauseMenu extends StatelessWidget {
  const PauseMenu(this.state, {required this.exit, super.key});
  final KitchenState state;
  final VoidCallback exit;
  @override
  Widget build(BuildContext context) {
    final s = context.kitchen;
    final tier = state.profile.qualityTier ?? 1;
    return ColoredBox(
      color: const Color(0xDA112A2B),
      child: SafeStage(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(s.paused, style: marketText(32, bold: true)),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  alignment: WrapAlignment.center,
                  children: [
                    MarketButton(
                      s.resume,
                      () => context.act(ActionType.resume),
                      primary: true,
                      icon: Icons.play_arrow_rounded,
                    ),
                    MarketButton(
                      s.restart,
                      () => context.act(ActionType.start, state.level),
                      icon: Icons.replay_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  alignment: WrapAlignment.center,
                  children: [
                    MarketButton(
                      "${s.music} · ${state.profile.sound ? s.on : s.off}",
                      () => context.act(ActionType.sound),
                      icon: Icons.volume_up_rounded,
                    ),
                    MarketButton(
                      "${s.vibration} · ${state.profile.haptics ? s.on : s.off}",
                      () => context.act(ActionType.haptics),
                      icon: Icons.vibration_rounded,
                    ),
                    MarketButton(
                      "${s.quality} · ${[s.qualityLow, s.qualityMedium, s.qualityHigh][tier]}",
                      () => context.act(
                        ActionType.quality,
                        (tier + 1) % KitchenProgress.qualityTiers,
                      ),
                      icon: Icons.auto_awesome_rounded,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                MarketButton(s.exit, exit, icon: Icons.exit_to_app_rounded),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class ShiftReceipt extends StatelessWidget {
  const ShiftReceipt(this.run, {required this.openProduct, super.key});
  final KitchenRun run;
  final VoidCallback openProduct;
  @override
  Widget build(BuildContext context) {
    final s = context.kitchen;
    final next = run.shift.number + 1;
    return MarketBackdrop(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Flexible(
              flex: 5,
              child: SingleChildScrollView(
                child: MarketPanel(
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        "${s.market} · ${s.shift} ${run.shift.number}",
                        style: marketText(12, color: paprika, bold: true),
                      ),
                      Text(
                        run.won ? s.won : s.lost,
                        style: marketText(26, color: ink, bold: true),
                      ),
                      const SizedBox(height: 7),
                      for (final line in [
                        (s.coins, run.coins),
                        (s.served, run.served),
                        (s.missed, run.missed),
                        (s.bestStreak, run.bestChain),
                      ])
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(line.$1, style: marketText(14, color: ink)),
                            Text(
                              "${line.$2}",
                              style: marketText(15, color: ink, bold: true),
                            ),
                          ],
                        ),
                      const SizedBox(height: 9),
                      MarketButton(
                        run.won ? (next > 12 ? s.complete : s.next) : s.retry,
                        () => context.act(
                          run.won
                              ? (next > 12
                                    ? ActionType.tickets
                                    : ActionType.brief)
                              : ActionType.start,
                          run.won ? next : run.shift.number,
                        ),
                        primary: true,
                        icon: Icons.arrow_forward_rounded,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Flexible(
              flex: 4,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Image.asset(
                      "$imageRoot${run.shift.product.key}.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  Text(
                    productName(s, run.shift.product),
                    style: marketText(16, bold: true),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 5),
                  MarketButton(
                    s.product,
                    openProduct,
                    icon: Icons.open_in_new_rounded,
                  ),
                  const SizedBox(height: 4),
                  MarketButton(
                    s.shop,
                    () => context.act(ActionType.shop),
                    icon: Icons.storefront_rounded,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
