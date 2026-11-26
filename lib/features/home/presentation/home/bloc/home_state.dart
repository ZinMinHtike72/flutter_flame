part of "home_bloc.dart";

enum HomeStatus { initial, loading, success, failure }

class HomeState extends Equatable {
  const HomeState({required this.status, this.errorMessage});

  factory HomeState.initial() => const HomeState(status: HomeStatus.initial);

  final HomeStatus status;
  final String? errorMessage;

  HomeState copyWith({HomeStatus? status, String? errorMessage}) =>
      HomeState(status: status ?? this.status, errorMessage: errorMessage);

  @override
  List<Object?> get props => [status, errorMessage];
}
