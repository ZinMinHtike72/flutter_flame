import "package:game_test/app/di/injection_container.dart";
import "package:game_test/features/home/presentation/home/bloc/home_bloc.dart";
import "package:get_it/get_it.dart";

final class HomeModule implements DependencyModule {
  const HomeModule();

  @override
  void register(GetIt getIt) {
    getIt.putFactoryIfAbsent<HomeBloc>(HomeBloc.new);
  }
}
