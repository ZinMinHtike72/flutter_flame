import "dart:math";
import "package:equatable/equatable.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/campaign.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/kitchen_run.dart";
import "package:yumyum_kitchen/src/features/kitchen/domain/progress.dart";

part "kitchen_event.dart";
part "kitchen_state.dart";

typedef RunFactory = KitchenRun Function(Shift shift, KitchenProgress profile);

class KitchenBloc extends Bloc<KitchenEvent, KitchenState> {
  KitchenBloc(this.repository, this.createRun) : super(KitchenState.initial()) {
    on<KitchenEvent>(
      _handle,
      transformer: (events, mapper) => events.asyncExpand(mapper),
    );
  }
  final ProgressRepository repository;
  final RunFactory createRun;
  KitchenRun? run;
  KitchenPage _shopReturn = KitchenPage.tickets;
  KitchenEvent _retry = const KitchenStarted();
  bool _suspended = false;
  void suspend() {
    _suspended = true;
    if (state.page == KitchenPage.live) {
      run?.paused = true;
      add(const KitchenAction(ActionType.pause));
    }
  }

  void foreground() {
    _suspended = false;
  }

  void tick(int ms) {
    final current = run;
    if (isClosed ||
        current == null ||
        current.paused ||
        current.ended ||
        state.page != KitchenPage.live) {
      return;
    }
    final previous = (
      current.secondsLeft,
      current.guide,
      current.feedbackSequence,
    );
    current.advance(ms);
    if (current.ended) {
      add(const KitchenAction(ActionType.settle));
    } else if (previous !=
        (current.secondsLeft, current.guide, current.feedbackSequence)) {
      add(const KitchenUpdated());
    }
  }

  void tap(Station station, int index) {
    if (state.page != KitchenPage.live || run == null) {
      return;
    }
    run!.tap(station, index);
    add(const KitchenUpdated());
  }

  Future<void> _handle(KitchenEvent event, Emitter<KitchenState> emit) async {
    try {
      switch (event) {
        case KitchenStarted():
          final profile = await repository.read();
          emit(
            state.copyWith(
              page: KitchenPage.entrance,
              profile: profile,
              level: profile.unlocked,
            ),
          );
        case KitchenUpdated():
          if (state.page == KitchenPage.live) {
            emit(state.copyWith(revision: state.revision + 1));
          }
        case KitchenAction():
          await _action(event, emit);
      }
    } on Exception {
      _retry = event;
      emit(state.copyWith(page: KitchenPage.failure));
    }
  }

  Future<void> _action(KitchenAction event, Emitter<KitchenState> emit) async {
    final index = event.index;
    switch (event.action) {
      case ActionType.recover:
        add(_retry);
      case ActionType.tickets:
        emit(state.copyWith(page: KitchenPage.tickets));
      case ActionType.brief:
        if (index >= 1 && index <= state.profile.unlocked) {
          emit(state.copyWith(page: KitchenPage.brief, level: index));
        }
      case ActionType.start:
        if (index < 1 || index > state.profile.unlocked) {
          return;
        }
        run = createRun(campaign[index - 1], state.profile)
          ..paused = _suspended;
        emit(
          state.copyWith(
            page: _suspended ? KitchenPage.pause : KitchenPage.live,
            level: index,
            revision: state.revision + 1,
          ),
        );
      case ActionType.pause:
        if (state.page == KitchenPage.live) {
          run?.paused = true;
          emit(state.copyWith(page: KitchenPage.pause));
        }
      case ActionType.resume:
        if (state.page == KitchenPage.pause && !_suspended) {
          run?.paused = false;
          emit(state.copyWith(page: KitchenPage.live));
        }
      case ActionType.settle:
        final current = run;
        if (current == null || !current.ended) {
          return;
        }
        final profile = await repository.update((p) => p.settle(current));
        emit(state.copyWith(page: KitchenPage.receipt, profile: profile));
      case ActionType.shop:
        if (state.page != KitchenPage.shop) {
          _shopReturn = state.page;
        }
        emit(
          state.copyWith(
            page: KitchenPage.shop,
            preview: Upgrade.values[index],
          ),
        );
      case ActionType.buy:
        final profile = await repository.update((p) => p.buy(state.preview));
        emit(state.copyWith(page: KitchenPage.shop, profile: profile));
      case ActionType.sound:
        final profile = await repository.update(
          (p) => p.preferences(soundOn: !p.sound),
        );
        emit(state.copyWith(profile: profile));
      case ActionType.haptics:
        final profile = await repository.update(
          (p) => p.preferences(hapticsOn: !p.haptics),
        );
        emit(state.copyWith(profile: profile));
      case ActionType.quality:
        final profile = await repository.update(
          (p) => p.preferences(tier: index),
        );
        emit(state.copyWith(profile: profile));
      case ActionType.benchmark:
        // The benchmark only fills in a tier nobody has chosen yet.
        final profile = await repository.update(
          (p) => p.qualityTier == null ? p.preferences(tier: index) : p,
        );
        emit(state.copyWith(profile: profile));
      case ActionType.back:
        final next = switch (state.page) {
          KitchenPage.shop => _shopReturn,
          KitchenPage.brief || KitchenPage.receipt => KitchenPage.tickets,
          KitchenPage.tickets || KitchenPage.pause => KitchenPage.entrance,
          _ => state.page,
        };
        emit(state.copyWith(page: next));
    }
  }
}

KitchenRun makeKitchenRun(
  Shift shift,
  KitchenProgress profile,
  String id,
  Random random,
) => KitchenRun(
  shift: shift,
  id: id,
  random: random,
  upgrades: profile.upgrades,
  tutorial: shift.number == 1 && !profile.best.containsKey(1),
);
