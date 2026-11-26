import "package:flutter/widgets.dart";
import "package:flutter_bloc/flutter_bloc.dart";
import "package:game_test/app/di/injection_container.dart";
import "package:game_test/features/home/presentation/home/bloc/home_bloc.dart";
import "package:game_test/features/home/presentation/home/widgets/home_view_content.dart";

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) => BlocProvider(
    create: (_) => getIt<HomeBloc>()..add(const HomeStarted()),
    child: const HomeViewContent(),
  );
}
