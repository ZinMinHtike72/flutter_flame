part of "kitchen_bloc.dart";

enum KitchenPage {
  loading,
  entrance,
  tickets,
  brief,
  live,
  pause,
  receipt,
  shop,
  failure,
}

class KitchenState extends Equatable {
  const KitchenState({
    required this.page,
    required this.profile,
    this.level = 1,
    this.revision = 0,
    this.preview = Upgrade.extraPot,
  });
  factory KitchenState.initial() =>
      const KitchenState(page: KitchenPage.loading, profile: KitchenProgress());
  final KitchenPage page;
  final KitchenProgress profile;
  final int level;
  final int revision;
  final Upgrade preview;
  KitchenState copyWith({
    KitchenPage? page,
    KitchenProgress? profile,
    int? level,
    int? revision,
    Upgrade? preview,
  }) => KitchenState(
    page: page ?? this.page,
    profile: profile ?? this.profile,
    level: level ?? this.level,
    revision: revision ?? this.revision,
    preview: preview ?? this.preview,
  );
  @override
  List<Object?> get props => [page, profile, level, revision, preview];
}
