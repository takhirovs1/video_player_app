import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../screens/main_screen.dart';

abstract class MainScreenController extends State<MainScreen> {
  StatefulNavigationShell get navigationShell => widget.navigationShell;

  bool isSelected(int index) => navigationShell.currentIndex == index;

  void onTabChanged(int index) => widget.navigationShell.goBranch(index);
}
