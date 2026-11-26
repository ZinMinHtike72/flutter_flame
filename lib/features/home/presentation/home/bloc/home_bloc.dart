import "package:equatable/equatable.dart";
import "package:flutter_bloc/flutter_bloc.dart";

part "home_event.dart";
part "home_state.dart";

class HomeBloc extends Bloc<HomeEvent, HomeState> {
  HomeBloc() : super(HomeState.initial()) {
    on<HomeStarted>(_onStarted);
  }

  void _onStarted(HomeStarted event, Emitter<HomeState> emit) {
    emit(state.copyWith(status: HomeStatus.success));
  }
}
