import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/utils/dimension.dart';
import '../../../../common/utils/gen/assets.gen.dart';
import '../controller/main_screen_controller.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends MainScreenController {
  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.bottomBackgroundColor))),
        child: BottomNavigationBar(
          currentIndex: navigationShell.currentIndex,
          onTap: onTabChanged,
          enableFeedback: true,
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.bottomBackgroundColor,
          selectedItemColor: AppColors.red,
          unselectedItemColor: AppColors.grey,
          selectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          unselectedLabelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w400),
          elevation: 10,
          items: [
            /// Home
            BottomNavigationBarItem(
              icon: Padding(
                padding: Dimension.pAll4,
                child: Assets.icons.home.svg(
                  height: 25,
                  width: 25,
                  color: isSelected(0) ? AppColors.red : AppColors.grey,
                ),
              ),
              label: 'Home',
            ),

            /// Downloads
            BottomNavigationBarItem(
              icon: Padding(
                padding: Dimension.pAll4,
                child: Assets.icons.downloads.svg(
                  height: 25,
                  width: 25,
                  color: isSelected(1) ? AppColors.red : AppColors.grey,
                ),
              ),

              label: 'Downloads',
            ),
          ],
        ),
      ),
    ),
  );
}
