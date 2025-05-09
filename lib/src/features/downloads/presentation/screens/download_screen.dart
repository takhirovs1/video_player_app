import 'package:flutter/material.dart';

import '../../../../common/constants/app_colors.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundColor,
    appBar: AppBar(title: const Text('Download Screen')),
    body: const Center(child: Text('Hello, world!')),
  );
}
