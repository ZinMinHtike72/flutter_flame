import "package:flutter/widgets.dart";
import "package:yumyum_kitchen/yumyum_kitchen.dart";

class HomeViewContent extends StatelessWidget {
  const HomeViewContent({super.key});
  @override
  Widget build(BuildContext context) =>
      const YumYumKitchenScreen(embedded: false);
}
