import "package:app_network/app_network.dart";
import "package:flutter_secure_storage/flutter_secure_storage.dart";
import "package:game_test/app/di/injection_container.dart";
import "package:game_test/core/constants/api_constants.dart";
import "package:game_test/core/env/app_env.dart";
import "package:game_test/core/env/app_flavor.dart";
import "package:game_test/core/network/secure_token_store.dart";
import "package:game_test/core/network/session_expiry_notifier.dart";
import "package:get_it/get_it.dart";
import "package:talker/talker.dart";

/// Registers shared infrastructure used by every feature.
final class CoreModule implements DependencyModule {
  /// Creates the module for the active build [flavor].
  const CoreModule(this.flavor);

  /// Flavor whose environment is registered.
  final AppFlavor flavor;
  @override
  void register(GetIt getIt) {
    getIt.putLazySingletonIfAbsent<AppFlavor>(() => flavor);
    getIt.putLazySingletonIfAbsent<AppEnv>(() => AppEnv(flavor));
    getIt.putLazySingletonIfAbsent<Talker>(Talker.new);
    getIt.putLazySingletonIfAbsent<FlutterSecureStorage>(
      () => const FlutterSecureStorage(),
    );
    getIt.putLazySingletonIfAbsent<NetworkTransport>(
      () => DioNetworkTransport(
        baseUri: ApiConstants.baseUri(getIt<AppEnv>().apiBaseUrl),
      ),
      dispose: (transport) {
        if (transport is DioNetworkTransport) {
          transport.close();
        }
      },
    );
    getIt.putLazySingletonIfAbsent<TokenStore>(
      () => SecureTokenStore(getIt<FlutterSecureStorage>()),
    );
    getIt.putLazySingletonIfAbsent<SessionExpiryNotifier>(
      SessionExpiryNotifier.new,
      dispose: (notifier) => notifier.close(),
    );
    // Switch to AuthMode.refreshToken with a TokenRefresher once the auth
    // feature defines the refresh endpoint.
    getIt.putLazySingletonIfAbsent<AuthSession>(() {
      late final AuthSession session;
      session = AuthSession(
        store: getIt<TokenStore>(),
        mode: AuthMode.accessTokenOnly,
        onUnauthorized: (event) {
          if (event.generation == session.generation) {
            getIt<SessionExpiryNotifier>().notify();
          }
        },
      );
      return session;
    });
    getIt.putLazySingletonIfAbsent<AppNetworkClient>(
      () => AppNetworkClient(
        transport: getIt<NetworkTransport>(),
        session: getIt<AuthSession>(),
      ),
    );
  }
}
