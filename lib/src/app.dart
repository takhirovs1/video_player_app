import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player_package/video_player_package.dart';

import 'router/app_routers.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) => RepositoryProvider(
    create: (context) => VideoPlayerControllerInterfaceImpl(),
    child: MaterialApp.router(debugShowCheckedModeBanner: false, title: 'Video Player App', routerConfig: router),
  );
}
