import 'package:flutter/material.dart';

import 'router/app_routers.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) =>
      MaterialApp.router(debugShowCheckedModeBanner: false, title: 'Video Player App', routerConfig: router);
}
