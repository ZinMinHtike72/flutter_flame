import "package:bloc_test/bloc_test.dart";
import "package:game_test/features/home/presentation/home/bloc/home_bloc.dart";

void main() {
  blocTest<HomeBloc, HomeState>(
    "starts the game home screen",
    build: HomeBloc.new,
    act: (bloc) => bloc.add(const HomeStarted()),
    expect: () => [const HomeState(status: HomeStatus.success)],
  );
}
