import "dart:async";
import "dart:math";
import "package:app_ui_kit/widgets/app_scaffold.dart";
import "package:app_ui_kit/widgets/app_snack_bar.dart";
import "package:flame/game.dart";
import "package:flutter/services.dart";
import "package:flutter/widgets.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:url_launcher/url_launcher.dart";
import "package:uuid/uuid.dart";
import "package:yumyum_kitchen/l10n/gen/kitchen_strings.dart";
import "package:yumyum_kitchen/src/features/kitchen/data/local_progress_repository.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/bloc/kitchen_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/kitchen_audio.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/game/yum_yum_kitchen_game.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_lobby.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/market_style.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/shift_overlays.dart";
import "package:yumyum_kitchen/src/features/kitchen/presentation/widgets/upgrade_shop.dart";

/// Push this screen from a Flutter host. Return false from [onOpenProduct]
/// to use the official product URL. Await the host product sheet until closed.
class YumYumKitchenScreen extends StatelessWidget {
  const YumYumKitchenScreen({
    super.key,
    this.onExit,
    this.onOpenProduct,
    this.embedded = true,
    this.showHitBoxes = false,
    this.restoreOrientations = const [
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ],
  });
  final VoidCallback? onExit;
  final Future<bool> Function(NoodleProduct product)? onOpenProduct;
  final bool embedded;

  /// Paints the safe stage, zones and hit boxes over the game (debug aid).
  final bool showHitBoxes;
  final List<DeviceOrientation> restoreOrientations;
  @override
  Widget build(BuildContext context) => Localizations.override(
    context: context,
    locale: Localizations.localeOf(context).languageCode == "my"
        ? const Locale("my")
        : const Locale("en"),
    delegates: KitchenStrings.localizationsDelegates,
    child: BlocProvider(
      create: (context) {
        // A host or test may provide a seeded Random for reproducible shifts.
        final random = context.read<Random?>() ?? Random();
        return KitchenBloc(
          LocalProgressRepository(),
          (shift, profile) =>
              makeKitchenRun(shift, profile, const Uuid().v4(), random),
        )..add(const KitchenStarted());
      },
      child: RepositoryProvider(
        create: (context) => _Session(
          context.read<KitchenBloc>(),
          context.read<KitchenAudio?>() ?? KitchenAudio(),
          embedded: embedded,
          restore: restoreOrientations,
        ),
        dispose: (session) => session.dispose(),
        child: _Content(this),
      ),
    ),
  );
}

class _Session {
  _Session(
    KitchenBloc bloc,
    KitchenAudio audio, {
    required this.embedded,
    required this.restore,
  }) : game = YumYumKitchenGame(bloc, audio),
       lifecycle = AppLifecycleListener(
         onInactive: bloc.suspend,
         onPause: bloc.suspend,
         onResume: bloc.foreground,
       ) {
    unawaited(orient(landscape));
    unawaited(
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky),
    );
  }
  static const landscape = [
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ];
  final List<DeviceOrientation> restore;
  final bool embedded;
  final AppLifecycleListener lifecycle;
  final YumYumKitchenGame game;
  bool disposed = false;
  bool handingOff = false;
  Future<void> _orientation = Future.value();
  Future<void> orient(List<DeviceOrientation> allowed) {
    _orientation = _orientation.then(
      (_) => SystemChrome.setPreferredOrientations(allowed),
    );
    return _orientation;
  }

  Future<void> leave() async {
    if (embedded) {
      await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      await orient(restore);
    }
  }

  void dispose() {
    disposed = true;
    lifecycle.dispose();
    unawaited(leave());
  }
}

class _Content extends StatelessWidget {
  const _Content(this.options);
  final YumYumKitchenScreen options;
  Future<void> _exit(BuildContext context) async {
    if (!options.embedded) {
      context.act(ActionType.back);
      return;
    }
    final session = context.read<_Session>();
    await session.leave();
    if (!context.mounted) {
      return;
    }
    if (options.onExit != null) {
      options.onExit!();
    } else if (Navigator.canPop(context)) {
      Navigator.pop(context);
    }
  }

  Future<void> _product(BuildContext context, NoodleProduct product) async {
    final session = context.read<_Session>();
    if (session.handingOff) {
      return;
    }
    session.handingOff = true;
    try {
      await session.leave();
      var handled = false;
      try {
        handled = await options.onOpenProduct?.call(product) ?? false;
      } on Exception {
        handled = false;
      }
      if (!handled &&
          !await launchUrl(
            product.officialPage,
            mode: LaunchMode.externalApplication,
          )) {
        throw StateError("Could not open URL");
      }
    } catch (_) {
      if (context.mounted) {
        AppSnackBar.showError(context, message: context.kitchen.linkFailed);
      }
    } finally {
      if (!session.disposed) {
        await session.orient(_Session.landscape);
      }
      session.handingOff = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = context.read<_Session>();
    final padding = MediaQuery.viewPaddingOf(context);
    final game = session.game
      ..reducedMotion = MediaQuery.disableAnimationsOf(context)
      ..showHitBoxes = options.showHitBoxes
      ..insets = Rect.fromLTRB(
        padding.left,
        padding.top,
        padding.right,
        padding.bottom,
      );
    return AppScaffold(
      backgroundColor: ink,
      body: SizedBox.expand(
        child: GameWidget<YumYumKitchenGame>(
          game: game,
          loadingBuilder: (context) => MarketBackdrop(
            entrance: true,
            child: Center(
              child: Text(
                context.kitchen.loading,
                style: marketText(16, bold: true),
              ),
            ),
          ),
          initialActiveOverlays: const ["kitchen"],
          overlayBuilderMap: {
            "kitchen": (context, game) =>
                BlocBuilder<KitchenBloc, KitchenState>(
                  builder: (context, state) => PopScope(
                    canPop: state.page == KitchenPage.entrance,
                    onPopInvokedWithResult: (didPop, result) {
                      if (didPop) {
                        return;
                      }
                      if (state.page == KitchenPage.live) {
                        context.act(ActionType.pause);
                      } else if (state.page == KitchenPage.pause) {
                        context.act(ActionType.resume);
                      } else {
                        context.act(ActionType.back);
                      }
                    },
                    child: ScrimGuard(
                      blocking: state.page != KitchenPage.live,
                      child: switch (state.page) {
                        KitchenPage.loading => Center(
                          child: Text(
                            context.kitchen.loading,
                            style: marketText(18),
                          ),
                        ),
                        KitchenPage.failure => MarketBackdrop(
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  context.kitchen.problem,
                                  style: marketText(16),
                                ),
                                MarketButton(
                                  context.kitchen.retry,
                                  () => context.act(ActionType.recover),
                                ),
                              ],
                            ),
                          ),
                        ),
                        KitchenPage.entrance => MarketEntrance(
                          state,
                          onExit: options.embedded
                              ? () => unawaited(_exit(context))
                              : null,
                        ),
                        KitchenPage.tickets => MarketTickets(state),
                        KitchenPage.brief => MarketBrief(state),
                        KitchenPage.live => ShiftHud(game.bloc.run!),
                        KitchenPage.pause => PauseMenu(
                          state,
                          exit: () => unawaited(_exit(context)),
                        ),
                        KitchenPage.receipt => ShiftReceipt(
                          game.bloc.run!,
                          openProduct: () => unawaited(
                            _product(context, game.bloc.run!.shift.product),
                          ),
                        ),
                        KitchenPage.shop => UpgradeShop(state),
                      },
                    ),
                  ),
                ),
          },
        ),
      ),
    );
  }
}
