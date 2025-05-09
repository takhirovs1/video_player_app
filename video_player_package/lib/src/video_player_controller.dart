import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

enum DownloadStatus { notStarted, downloading, completed, canceled, failed }

class VideoPlayerController {
  final String url;
  final ValueNotifier<DownloadStatus> downloadStatus = ValueNotifier(
    DownloadStatus.notStarted,
  );
  final ValueNotifier<double> progress = ValueNotifier(0.0);

  String? _localFilePath;
  CancelToken? _cancelToken;

  VideoPlayerController(this.url);

  /// Starts the download and updates the progress and status.
  Future<void> startDownload() async {
    downloadStatus.value = DownloadStatus.downloading;
    progress.value = 0.0;
    _cancelToken = CancelToken();

    try {
      final dir = await getApplicationDocumentsDirectory();
      final filePath = '${dir.path}/${Uri.parse(url).pathSegments.last}';
      _localFilePath = filePath;

      await Dio().download(
        url,
        filePath,
        cancelToken: _cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            progress.value = received / total;
          }
        },
      );

      // Mark download as complete
      downloadStatus.value = DownloadStatus.completed;
    } on DioException catch (e) {
      if (e.type == DioExceptionType.cancel) {
        // Handle cancellation
        downloadStatus.value = DownloadStatus.canceled;
      } else {
        // Handle other errors
        debugPrint('Download failed: $e');
        downloadStatus.value = DownloadStatus.failed;
      }
    } catch (e) {
      debugPrint('Unexpected error: $e');
      downloadStatus.value = DownloadStatus.failed;
    }
  }

  /// Cancels the current download if in progress.
  void cancelDownload() {
    if (downloadStatus.value == DownloadStatus.downloading) {
      _cancelToken?.cancel();
    }
  }

  /// Removes the downloaded file.
  Future<void> removeDownload() async {
    if (_localFilePath != null) {
      final file = File(_localFilePath!);
      if (await file.exists()) {
        await file.delete();
      }
      _localFilePath = null;
    }
    downloadStatus.value = DownloadStatus.notStarted;
    progress.value = 0.0;
  }

  /// Releases the resources.
  void dispose() {
    downloadStatus.dispose();
    progress.dispose();
  }

  /// Returns the local file path if exists, otherwise the remote URL.
  String get videoSource => _localFilePath ?? url;

  /// Returns true if the file is already downloaded.
  Future<bool> get isDownloaded async {
    if (_localFilePath == null) return false;
    final file = File(_localFilePath!);
    return file.exists();
  }
}
