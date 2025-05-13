import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:video_player_package/video_player_package.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../services/local_source.dart';
import '../screens/view_screen.dart';

mixin ViewScreenController on State<ViewScreen> {
  VideoPlayerControllerInterface get controller => context.read<VideoPlayerControllerInterfaceImpl>();
  bool isFullscreen = false;
  DownloadData? data;

  String get url => widget.videoModel.url;

  // Initialize the video controller and add listener for downloadStatus changes
  Future<void> initializeController() async {
    controller.statusStream().listen((event) async {
      if (event.url == url) {
        data = event;
        setState(() {});
        if (event.status == DownloadStatus.completed) {
          await LocalSource.saveVideo(widget.videoModel.copyWith(path: event.path));
        }
      }
    });
    data = await controller.getInitialData(url);
    if (data?.status == DownloadStatus.notStarted) {
      final video = LocalSource.getSingleDownloadedVideo(url);
      if (video != null) {
        data = DownloadData(DownloadStatus.completed, url, 1, video.path);
      }
    }
    setState(() {});
  }

  // Toggle fullscreen mode
  void toggleFullscreen() {
    setState(() {
      isFullscreen = !isFullscreen;
    });
  }

  // Start the download
  Future<void> downloadVideo() async {
    await controller.startDownload(url: url, onProgress: (progress) {});
  }

  // Cancel the ongoing download
  Future<void> cancelDownload() async {
    await LocalSource.deleteVideo(widget.videoModel);
    await controller.cancelDownload(url);
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
        return AppColors.redAccent;
      case DownloadStatus.failed:
        return AppColors.red;
    }
  }

  // Remove the downloaded file
  Future<void> removeDownload() async {
    await LocalSource.deleteVideo(widget.videoModel);
    await controller.removeDownload(url);
  }
}
