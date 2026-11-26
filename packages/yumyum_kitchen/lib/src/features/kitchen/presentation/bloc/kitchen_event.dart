part of "kitchen_bloc.dart";

sealed class KitchenEvent extends Equatable {
  const KitchenEvent();
  @override
  List<Object?> get props => [];
}

final class KitchenStarted extends KitchenEvent {
  const KitchenStarted();
}

final class KitchenUpdated extends KitchenEvent {
  const KitchenUpdated();
}

enum ActionType {
  tickets,
  brief,
  start,
  pause,
  resume,
  settle,
  shop,
  buy,
  sound,
  haptics,
  back,
  recover,
}

final class KitchenAction extends KitchenEvent {
  const KitchenAction(this.action, [this.index = 0]);
  final ActionType action;
  final int index;
  @override
  List<Object?> get props => [action, index];
}
