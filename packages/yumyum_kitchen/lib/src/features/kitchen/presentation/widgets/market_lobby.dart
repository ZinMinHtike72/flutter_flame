import "package:flutter/material.dart" show Icons;
import "package:flutter/widgets.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_style.dart";

class MarketEntrance extends StatelessWidget {
  const MarketEntrance(this.state, {required this.onExit, super.key});
  final KitchenState state;
  final VoidCallback? onExit;
  @override
  Widget build(BuildContext context) {
    final s = context.kitchen;
    final returning = state.profile.settled.isNotEmpty;
    return MarketBackdrop(
      entrance: true,
      child: LayoutBuilder(
        builder: (context, box) => Stack(
          children: [
            Positioned(
              left: box.maxWidth * .065,
              top: box.maxHeight * .075,
              bottom: box.maxHeight * .07,
              width: box.maxWidth * .48,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Image.asset(
                      "${imageRoot}logo.png",
                      width: box.maxHeight * .36,
                      fit: BoxFit.contain,
                    ),
                  ),
                  SizedBox(height: box.maxHeight * .055),
                  Text(
                    s.market.toUpperCase(),
                    style: marketText(
                      13,
                      color: gold,
                      bold: true,
                    ).copyWith(letterSpacing: 2.0),
                  ),
                  const SizedBox(height: 6),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      s.title,
                      style: marketText(
                        box.maxHeight * .135,
                        bold: true,
                      ).copyWith(letterSpacing: -2),
                    ),
                  ),
                  SizedBox(height: box.maxHeight * .065),
                  MarketButton(
                    returning ? s.continueGame : s.play,
                    () => context.act(
                      returning ? ActionType.tickets : ActionType.start,
                      1,
                    ),
                    primary: true,
                    icon: Icons.play_arrow_rounded,
                  ),
                ],
              ),
            ),
            if (onExit != null)
              Positioned(
                right: 14,
                top: 12,
                child: MarketButton(
                  s.exit,
                  onExit!,
                  icon: Icons.close_rounded,
                  compact: true,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class MarketTickets extends StatelessWidget {
  const MarketTickets(this.state, {super.key});
  final KitchenState state;
  @override
  Widget build(BuildContext context) {
    final s = context.kitchen;
    return MarketBackdrop(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Column(
          children: [
            MarketHeader(
              s.tickets,
              trailing: MarketButton(
                s.shop,
                () => context.act(ActionType.shop),
                icon: Icons.storefront_rounded,
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: List.generate(
                  3,
                  (group) => Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      child: Column(
                        children: [
                          Expanded(
                            child: Image.asset(
                              "$imageRoot${NoodleProduct.values[group].key}.png",
                              fit: BoxFit.contain,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Text(
                              chapter(s, group * 4 + 1),
                              style: marketText(15, color: gold, bold: true),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          for (final row in [0, 1])
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Row(
                                children: List.generate(2, (col) {
                                  final level = group * 4 + row * 2 + col + 1;
                                  final enabled =
                                      level <= state.profile.unlocked;
                                  return Expanded(
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 2,
                                      ),
                                      child: MarketButton(
                                        "$level",
                                        () => context.act(
                                          ActionType.brief,
                                          level,
                                        ),
                                        primary: enabled,
                                        enabled: enabled,
                                        icon: enabled
                                            ? Icons.confirmation_number_outlined
                                            : Icons.lock_outline_rounded,
                                      ),
                                    ),
                                  );
                                }),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MarketBrief extends StatelessWidget {
  const MarketBrief(this.state, {super.key});
  final KitchenState state;
  @override
  Widget build(BuildContext context) {
    final s = context.kitchen;
    final shift = campaign[state.level - 1];
    return MarketBackdrop(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            MarketHeader("${s.shift} ${shift.number}"),
            const SizedBox(height: 8),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Image.asset(
                      "$imageRoot${shift.product.key}.png",
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(width: 24),
                  Flexible(
                    child: SingleChildScrollView(
                      child: MarketPanel(
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              productName(s, shift.product),
                              style: marketText(21, color: ink, bold: true),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "${s.goal} · ${goalText(s, shift)}",
                              style: marketText(16, color: ink),
                            ),
                            Text(
                              "${s.best} · ${state.profile.best[shift.number] ?? 0}",
                              style: marketText(14, color: ink),
                            ),
                            const SizedBox(height: 12),
                            MarketButton(
                              s.start,
                              () => context.act(ActionType.start, shift.number),
                              primary: true,
                              icon: Icons.play_arrow_rounded,
                            ),
                          ],
                        ),
                      ),
                    ),
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
