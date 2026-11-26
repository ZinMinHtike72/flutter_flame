import "dart:async";

import "package:game_test/core/di/core_module.dart";
import "package:game_test/core/env/app_flavor.dart";
import "package:game_test/features/home/di/home_module.dart";
import "package:get_it/get_it.dart";

final GetIt getIt = GetIt.instance;

abstract interface class DependencyModule {
  void register(GetIt getIt);
}

extension AppRegistrations on GetIt {
  void putLazySingletonIfAbsent<T extends Object>(
    T Function() factory, {
    FutureOr<void> Function(T instance)? dispose,
  }) {
    if (!isRegistered<T>()) {
      registerLazySingleton<T>(factory, dispose: dispose);
    }
  }

  void putFactoryIfAbsent<T extends Object>(T Function() factory) {
    if (!isRegistered<T>()) {
      registerFactory<T>(factory);
    }
  }
}

void configureDependencies({required AppFlavor flavor}) {
  CoreModule(flavor).register(getIt);
  const HomeModule().register(getIt);
}
