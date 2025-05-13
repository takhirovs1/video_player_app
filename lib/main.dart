import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'src/app.dart';
import 'src/services/local_source.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await LocalSource.init();
  // await LocalSource.clear();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp, DeviceOrientation.portraitUp]);
  runApp(const App());
}
