#!/usr/bin/env bash
# Scaffolds a Clean Architecture feature under lib/features/<name>/.
# Usage: make create-feature NAME=game_level ENTITY=GameLevel
set -euo pipefail

NAME="${1:-}"
ENTITY="${2:-}"
if [[ -z "$NAME" || -z "$ENTITY" ]]; then
  echo "Usage: make create-feature NAME=<snake_case> ENTITY=<PascalCase>" >&2
  exit 1
fi
if [[ ! "$NAME" =~ ^[a-z][a-z0-9_]*$ || ! "$ENTITY" =~ ^[A-Z][A-Za-z0-9]*$ ]]; then
  echo "NAME must be snake_case and ENTITY must be PascalCase." >&2
  exit 1
fi

PKG="game_test"
ROOT="lib/features/$NAME"
if [[ -e "$ROOT" ]]; then
  echo "$ROOT already exists." >&2
  exit 1
fi

PASCAL="$(echo "$NAME" | awk -F_ '{for (i = 1; i <= NF; i++) printf "%s", toupper(substr($i, 1, 1)) substr($i, 2)}')"
ENTITY_FILE="$(echo "$ENTITY" | sed -E 's/([a-z0-9])([A-Z])/\1_\2/g' | tr '[:upper:]' '[:lower:]')"
IMPORT="package:$PKG/features/$NAME"

mkdir -p "$ROOT"/{data/{datasources,models,repositories},domain/{entities,repositories,usecases},presentation/"$NAME"/{bloc,view,widgets},di}

# Domain
cat > "$ROOT/domain/entities/$ENTITY_FILE.dart" <<EOF
/// Pure business object for $ENTITY. No serialization here.
final class $ENTITY {
  /// Creates a $ENTITY.
  const $ENTITY({required this.id});

  /// Stable identifier.
  final String id;
}
EOF

cat > "$ROOT/domain/repositories/${NAME}_repository.dart" <<EOF
/// Data access boundary for the $NAME feature.
abstract interface class ${PASCAL}Repository {}
EOF

cat > "$ROOT/domain/domain.dart" <<EOF
export "$IMPORT/domain/entities/$ENTITY_FILE.dart";
export "$IMPORT/domain/repositories/${NAME}_repository.dart";
EOF

# Data
cat > "$ROOT/data/datasources/${NAME}_remote_data_source.dart" <<EOF
import "package:app_network/app_network.dart";

/// Remote API calls for the $NAME feature.
final class ${PASCAL}RemoteDataSource {
  /// Injects the shared network client.
  const ${PASCAL}RemoteDataSource(this.client);

  /// Shared authenticated client.
  final AppNetworkClient client;
}
EOF

cat > "$ROOT/data/repositories/${NAME}_repository_impl.dart" <<EOF
import "$IMPORT/data/datasources/${NAME}_remote_data_source.dart";
import "$IMPORT/domain/repositories/${NAME}_repository.dart";

/// Default [${PASCAL}Repository] backed by the remote API.
final class ${PASCAL}RepositoryImpl implements ${PASCAL}Repository {
  /// Injects data sources.
  const ${PASCAL}RepositoryImpl(this.remoteDataSource);

  /// Remote API calls.
  final ${PASCAL}RemoteDataSource remoteDataSource;
}
EOF

cat > "$ROOT/data/data.dart" <<EOF
export "$IMPORT/data/datasources/${NAME}_remote_data_source.dart";
export "$IMPORT/data/repositories/${NAME}_repository_impl.dart";
EOF

# Presentation
SCREEN="$ROOT/presentation/$NAME"
cat > "$SCREEN/bloc/${NAME}_bloc.dart" <<EOF
import "package:equatable/equatable.dart";
import "package:flutter_bloc/flutter_bloc.dart";

part "${NAME}_event.dart";
part "${NAME}_state.dart";

/// Screen state for the $NAME feature.
class ${PASCAL}Bloc extends Bloc<${PASCAL}Event, ${PASCAL}State> {
  /// Registers event handlers.
  ${PASCAL}Bloc() : super(${PASCAL}State.initial()) {
    on<${PASCAL}Started>(_onStarted);
  }

  void _onStarted(${PASCAL}Started event, Emitter<${PASCAL}State> emit) {
    emit(state.copyWith(status: ${PASCAL}Status.success));
  }
}
EOF

cat > "$SCREEN/bloc/${NAME}_event.dart" <<EOF
part of "${NAME}_bloc.dart";

/// Inputs to [${PASCAL}Bloc].
sealed class ${PASCAL}Event extends Equatable {
  const ${PASCAL}Event();
  @override
  List<Object?> get props => [];
}

/// The screen was opened.
final class ${PASCAL}Started extends ${PASCAL}Event {
  /// Creates the start event.
  const ${PASCAL}Started();
}
EOF

cat > "$SCREEN/bloc/${NAME}_state.dart" <<EOF
part of "${NAME}_bloc.dart";

/// Lifecycle of the $NAME screen.
enum ${PASCAL}Status { initial, loading, success, failure }

/// Immutable state of [${PASCAL}Bloc].
class ${PASCAL}State extends Equatable {
  /// Creates a state.
  const ${PASCAL}State({required this.status, this.errorMessage});

  /// Initial state before loading.
  factory ${PASCAL}State.initial() =>
      const ${PASCAL}State(status: ${PASCAL}Status.initial);

  /// Current lifecycle status.
  final ${PASCAL}Status status;

  /// Failure detail for the user, if any.
  final String? errorMessage;

  /// Returns a copy; [errorMessage] resets unless supplied.
  ${PASCAL}State copyWith({${PASCAL}Status? status, String? errorMessage}) =>
      ${PASCAL}State(
        status: status ?? this.status,
        errorMessage: errorMessage,
      );

  @override
  List<Object?> get props => [status, errorMessage];
}
EOF

cat > "$SCREEN/view/${NAME}_screen.dart" <<EOF
import "package:flutter/widgets.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:$PKG/app/di/injection_container.dart";
import "$IMPORT/presentation/$NAME/bloc/${NAME}_bloc.dart";
import "$IMPORT/presentation/$NAME/widgets/widgets.dart";

/// Entry point for the $NAME screen; provides its BLoC.
class ${PASCAL}Screen extends StatelessWidget {
  /// Creates the screen.
  const ${PASCAL}Screen({super.key});
  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<${PASCAL}Bloc>()..add(const ${PASCAL}Started()),
    child: const ${PASCAL}ViewContent(),
  );
}
EOF

cat > "$SCREEN/widgets/${NAME}_view_content.dart" <<EOF
import "package:app_ui_kit/app_ui_kit.dart";
import "package:flutter/widgets.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "$IMPORT/presentation/$NAME/bloc/${NAME}_bloc.dart";

/// Renders [${PASCAL}State] and reacts to side effects.
class ${PASCAL}ViewContent extends StatelessWidget {
  /// Creates the view content.
  const ${PASCAL}ViewContent({super.key});
  @override
  Widget build(BuildContext context) =>
      BlocListener<${PASCAL}Bloc, ${PASCAL}State>(
        listenWhen: (previous, current) => previous.status != current.status,
        listener: (context, state) {
          final message = state.errorMessage;
          if (state.status == ${PASCAL}Status.failure && message != null) {
            AppSnackBar.showError(context, message: message);
          }
        },
        child: BlocBuilder<${PASCAL}Bloc, ${PASCAL}State>(
          builder: (context, state) => AppScaffold(
            body: SafeArea(
              child: Center(
                child: state.status == ${PASCAL}Status.loading
                    ? const AppLoadingIndicator()
                    : const SizedBox.shrink(),
              ),
            ),
          ),
        ),
      );
}
EOF

cat > "$SCREEN/widgets/widgets.dart" <<EOF
export "$IMPORT/presentation/$NAME/widgets/${NAME}_view_content.dart";
EOF

cat > "$SCREEN/$NAME.dart" <<EOF
export "$IMPORT/presentation/$NAME/bloc/${NAME}_bloc.dart";
export "$IMPORT/presentation/$NAME/view/${NAME}_screen.dart";
export "$IMPORT/presentation/$NAME/widgets/widgets.dart";
EOF

cat > "$ROOT/presentation/presentation.dart" <<EOF
export "$IMPORT/presentation/$NAME/$NAME.dart";
EOF

# DI
cat > "$ROOT/di/${NAME}_module.dart" <<EOF
import "package:app_network/app_network.dart";
import "package:$PKG/app/di/injection_container.dart";
import "$IMPORT/data/data.dart";
import "$IMPORT/domain/domain.dart";
import "$IMPORT/presentation/presentation.dart";
import "package:get_it/get_it.dart";

/// Registers the $NAME feature's dependencies.
final class ${PASCAL}Module implements DependencyModule {
  /// Creates a stateless dependency module.
  const ${PASCAL}Module();
  @override
  void register(GetIt getIt) {
    getIt.putLazySingletonIfAbsent<${PASCAL}RemoteDataSource>(
      () => ${PASCAL}RemoteDataSource(getIt<AppNetworkClient>()),
    );
    getIt.putLazySingletonIfAbsent<${PASCAL}Repository>(
      () => ${PASCAL}RepositoryImpl(getIt<${PASCAL}RemoteDataSource>()),
    );
    getIt.putFactoryIfAbsent<${PASCAL}Bloc>(${PASCAL}Bloc.new);
  }
}
EOF

cat > "$ROOT/$NAME.dart" <<EOF
export "$IMPORT/data/data.dart";
export "$IMPORT/di/${NAME}_module.dart";
export "$IMPORT/domain/domain.dart";
export "$IMPORT/presentation/presentation.dart";
EOF

dart format "$ROOT" >/dev/null

cat <<EOF
Created $ROOT

Next steps:
  1. Register the module in lib/app/di/injection_container.dart:
       const ${PASCAL}Module().register(getIt);
  2. Add a path to lib/app/router/route_path.dart and a GoRoute in app_router.dart.
  3. Write the plan file in .plan/ and run: flutter analyze $ROOT
EOF
