import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../features/downloads/presentation/screens/download_screen.dart';
import '../features/home/data/models/video_model.dart';
import '../features/home/data/repository/video_repository.dart';
import '../features/home/presentation/bloc/video_bloc.dart';
import '../features/home/presentation/screens/home_screen.dart';
import '../features/main/presentation/screens/main_screen.dart';
import '../features/view/presentation/screens/view_screen.dart';
import 'name_routes.dart';

final rootNavigatorKey = GlobalKey<NavigatorState>();

GoRouter router = GoRouter(
  initialLocation: Routes.home,
  navigatorKey: rootNavigatorKey,
  debugLogDiagnostics: true,
  routes: [
    StatefulShellRoute.indexedStack(
      parentNavigatorKey: rootNavigatorKey,
      builder: (context, state, navigationShell) => MainScreen(key: state.pageKey, navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          initialLocation: Routes.home,
          routes: [
            GoRoute(
              path: Routes.home,
              name: Routes.home,
              builder:
                  (context, state) => BlocProvider(
                    create: (_) => VideoBloc(videoRepository: VideoRepositoryImpl()),
                    child: HomeScreen(),
                  ),
            ),
          ],
        ),
        StatefulShellBranch(
          initialLocation: Routes.downloads,
          routes: [
            GoRoute(
              path: Routes.downloads,
              name: Routes.downloads,
              builder: (context, state) => const DownloadScreen(),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: Routes.view,
      name: Routes.view,

      builder: (context, state) {
        final videoModel = state.extra as VideoModel;
        return ViewScreen(videoModel: videoModel);
      },
    ),
  ],
);
