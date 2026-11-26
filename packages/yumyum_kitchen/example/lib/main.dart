import "package:flutter/material.dart";
import "package:yumyum_kitchen/yumyum_kitchen.dart";

void main()=>runApp(const MaterialApp(home:KitchenHostExample()));

/// The host owns navigation. Return false when its catalog has no matching SKU.
class KitchenHostExample extends StatelessWidget {
  const KitchenHostExample({super.key});
  @override
  Widget build(BuildContext context)=>Scaffold(body:Center(child:FilledButton(
    onPressed:()=>Navigator.of(context).push<void>(MaterialPageRoute(builder:(routeContext)=>YumYumKitchenScreen(
      onExit:()=>Navigator.pop(routeContext),
      onOpenProduct:(product) async {
        await showModalBottomSheet<void>(context:routeContext,builder:(_)=>SafeArea(child:ListTile(title:Text(product.key),subtitle:Text(product.officialPage.toString()))));
        return true;
      },
    ))),child:const Text("Open kitchen"))));
}
