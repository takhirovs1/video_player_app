import 'package:flutter/material.dart';
import 'package:video_player_package/video_player_package.dart';

import '../../../../common/constants/app_colors.dart';
import '../screens/view_screen.dart';

mixin ViewScreenController on State<ViewScreen> {
  late final VideoPlayerController videoController;
  bool isFullscreen = false;

  // Initialize the video controller and add listener for downloadStatus changes
  void initializeController(String url) {
    videoController = VideoPlayerController(url);
    videoController.downloadStatus.addListener(() {
      setState(() {
        debugPrint('Download Status Updated: ${videoController.downloadStatus.value}');
      });
    });
  }

  // Toggle fullscreen mode
  void toggleFullscreen() {
    setState(() {
      isFullscreen = !isFullscreen;
    });
  }

  // Start the download
  Future<void> downloadVideo() async {
    await videoController.startDownload();
  }

  // Cancel the ongoing download
  Future<void> cancelDownload() async {
    videoController.cancelDownload();
  }

  // Get the appropriate text for the button based on the download status
  String getButtonText(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.notStarted:
        return 'Download Video';
      case DownloadStatus.downloading:
        return 'Cancel Download';
      case DownloadStatus.completed:
        return 'Remove Download';
      case DownloadStatus.canceled:
        return 'Download Canceled';
      case DownloadStatus.failed:
        return 'Retry Download';
    }
  }

  // Get the appropriate color for the button based on the download status
  Color getButtonColor(DownloadStatus status) {
    switch (status) {
      case DownloadStatus.notStarted:
        return AppColors.red;
      case DownloadStatus.downloading:
        return AppColors.red.withOpacity(0.5);
      case DownloadStatus.completed:
        return AppColors.grey;
      case DownloadStatus.canceled:
        return AppColors.purple;
      case DownloadStatus.failed:
        return AppColors.red;
    }
  }

  // Get the download progress as a percentage
  double getProgress() {
    if (videoController.downloadStatus.value == DownloadStatus.downloading) {
      return videoController.progress.value;
    }
    return 0;
  }

  // Remove the downloaded file
  Future<void> removeDownload() async {
    await videoController.removeDownload();
  }
}
