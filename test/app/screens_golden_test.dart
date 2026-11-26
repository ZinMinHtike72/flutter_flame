import "package:flutter/material.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:flutter_test/flutter_test.dart";
import "package:game_test/app/app.dart";
import "package:game_test/app/di/injection_container.dart";
import "package:game_test/core/env/app_flavor.dart";
import "package:shared_preferences/shared_preferences.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_lobby.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/shift_overlays.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/upgrade_shop.dart";
import "../helpers/golden.dart";

void main(){
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(loadAppFonts);
  for(final mode in ["light","dark","myanmar_small"]){
    testWidgets("landscape kitchen screen flow $mode",(tester)async{
      await getIt.reset();configureDependencies(flavor:AppFlavor.development);
      SharedPreferences.setMockInitialValues({});
      useGoldenDevice(tester,size:mode=="myanmar_small"?goldenSmallPhone:const Size(852,393),locale:Locale(mode=="myanmar_small"?"my":"en"),brightness:mode=="dark"?Brightness.dark:Brightness.light);
      await tester.pumpWidget(withTestAudio(const RepaintBoundary(key:goldenKey,child:App())));
      await waitForWidget(tester,find.byType(MarketEntrance));
      Future<void> snap(String name) async {
        await tester.runAsync(()=>Future<void>.delayed(const Duration(milliseconds:100)));
        await tester.pump();await expectGolden(tester,"${name}_$mode");
      }
      await snap("entrance");
      final bloc=tester.element(find.byType(MarketEntrance)).read<KitchenBloc>();
      Future<void> action(ActionType type,Type widget,[int index=0]) async {
        bloc.add(KitchenAction(type,index));await waitForWidget(tester,find.byType(widget));
      }
      await action(ActionType.tickets,MarketTickets);await snap("tickets");
      await action(ActionType.brief,MarketBrief,1);await snap("brief");
      await action(ActionType.start,ShiftHud,1);await snap("tutorial");
      final size=tester.getRect(find.byType(ShiftHud));
      final scale=(size.width/1280).clamp(0,size.height/720).toDouble();
      final origin=size.center-Offset(640*scale,360*scale);
      Future<void> tap(double x,double y)async{await tester.tapAt(origin+Offset(x*scale,y*scale));await tester.pump();}
      await tap(130,520);bloc.tick(3000);await tester.pump();await tap(320,520);await tap(810,515);
      expect(bloc.run!.served,1);await snap("live");
      await action(ActionType.pause,PauseMenu);await snap("pause");
      await action(ActionType.resume,ShiftHud);bloc.tick(45000);await waitForWidget(tester,find.byType(ShiftReceipt));await snap("receipt");
      await action(ActionType.shop,UpgradeShop);await snap("upgrades");
      expect(tester.takeException(),isNull);
      await tester.pumpWidget(const SizedBox());await tester.pump();
    },skip:!goldensSupported);
  }
}
