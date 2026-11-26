import "package:flutter/material.dart" show Icons;
import "package:flutter/widgets.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_style.dart";

class UpgradeShop extends StatelessWidget {
  const UpgradeShop(this.state, {super.key});
  final KitchenState state;
  @override
  Widget build(BuildContext context) {
    final s = context.kitchen;
    final item = state.preview;
    final owned = state.profile.upgrades.contains(item);
    final names = [s.extraPot, s.fastBoil, s.premiumBowl];
    return MarketBackdrop(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            MarketHeader(
              s.shop,
              trailing: Text(
                "${s.balance} · ${state.profile.wallet}",
                style: marketText(16, color: gold, bold: true),
              ),
            ),
            const SizedBox(height: 6),
            Expanded(
              child: Row(
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          for (final upgrade in Upgrade.values)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: MarketButton(
                                names[upgrade.index],
                                () =>
                                    context.act(ActionType.shop, upgrade.index),
                                primary: item == upgrade,
                                icon: [
                                  Icons.soup_kitchen_rounded,
                                  Icons.local_fire_department_rounded,
                                  Icons.ramen_dining_rounded,
                                ][upgrade.index],
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: MarketPanel(
                      Column(
                        children: [
                          Expanded(
                            child: Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  "${imageRoot}counter.webp",
                                  fit: BoxFit.cover,
                                ),
                                Align(
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      for (
                                        var i = 0;
                                        i < (item == Upgrade.extraPot ? 2 : 1);
                                        i++
                                      )
                                        Flexible(
                                          child: Image.asset(
                                            "${imageRoot}preview_${item.index}.webp",
                                            fit: BoxFit.contain,
                                          ),
                                        ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            [s.potHint, s.boilHint, s.valueHint][item.index],
                            style: marketText(13, color: ink, bold: true),
                            textAlign: TextAlign.center,
                          ),
                          MarketButton(
                            owned ? s.owned : "${s.buy} · ${item.price}",
                            () => context.act(ActionType.buy),
                            primary: true,
                            enabled:
                                !owned && state.profile.wallet >= item.price,
                          ),
                        ],
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
