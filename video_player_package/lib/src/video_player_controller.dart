import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:video_player_package/src/download_manager.dart';
import 'package:video_player_package/video_player_package.dart';

enum DownloadStatus { notStarted, downloading, completed, canceled, failed }

typedef ProgressCallback = void Function(double progress);


abstract class VideoPlayerControllerInterface {
  const VideoPlayerControllerInterface();
  Stream<DownloadData> statusStream();
  Future<bool> isExist(String url);

  Future<void> startDownload({
    required String url,
    required ProgressCallback onProgress,
  });

  Future<void> cancelDownload(String url);

  Future<void> removeDownload(String url);

  Future<void> dispose();

  Future<File?> getFile(String url);

  Future<DownloadData> getInitialData(String url);
}

class VideoPlayerControllerInterfaceImpl
    extends VideoPlayerControllerInterface {
  static final Map<String, CancelToken> _cancelMap = {};
  final DownloadManagerInterface _downloadManager;
  final StreamController<DownloadData> _streamController;

  VideoPlayerControllerInterfaceImpl()
    : _downloadManager = DownloadManagerImpl(),
      _streamController = StreamController.broadcast();

  @override
  Stream<DownloadData> statusStream() => _streamController.stream;

  @override
  Future<void> cancelDownload(String url) async {
    _cancelMap[url]?.cancel();
    _cancelMap.remove(url);
    _streamController.add(DownloadData(DownloadStatus.canceled, url, 0));
  }

  @override
  Future<bool> isExist(String url) async {
    final file = await _downloadManager.file(url);
    return file != null;
  }

  @override
  Future<void> removeDownload(String url) async {
    _downloadManager.removeDownload(url);
    _cancelMap.remove(url);
    _streamController.add(DownloadData(DownloadStatus.notStarted, url, 0));
  }

  @override
  Future<void> startDownload({
    required String url,
    required ProgressCallback onProgress,
  }) async {
    final cancelToken = await _downloadManager.startDownload(url, (progress) {
      onProgress.call(progress);
      _streamController.add(
        DownloadData(
          switch (progress) {
            1 => DownloadStatus.completed,
            _ when !_cancelMap.containsKey(url) => DownloadStatus.canceled,
            _ => DownloadStatus.downloading,
          },
          url,
          progress,
        ),
      );
    });

    _cancelMap[url] = cancelToken;
  }

  @override
  Future<void> dispose() async {
    _cancelMap.clear();
    _streamController.close();
  }

  @override
  Future<File?> getFile(String url) async => await _downloadManager.file(url);

  @override
  Future<DownloadData> getInitialData(String url) async {
    final file = await getFile(url);
    if (file != null) {
      return DownloadData(DownloadStatus.completed, url, 1);
    }
    return _streamController.stream.lastWhere(
      (element) => element.url == url,
      orElse: () => DownloadData(DownloadStatus.notStarted, url, 0),
    );
  }
}
