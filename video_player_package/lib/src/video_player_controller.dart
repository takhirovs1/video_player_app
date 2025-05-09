import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:video_player_package/src/download_manager.dart';
import 'package:video_player_package/src/models/download_data_model.dart';
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
    if (url.endsWith('.m3u8')) {
      final cancelToken = CancelToken();
      _cancelMap[url] = cancelToken;
     await downloadM3u8(url, onProgress);
      DownloadData(DownloadStatus.downloading, url, 0);
    } else {
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
  }

  Future<void> downloadM3u8(String url, ProgressCallback onProgress) async {
    try {
      final playlistContent = await _downloadManager.getM3u8Content(url);
      final lines = playlistContent.split('\n');
      final segmentUrls =
          lines
              .where((line) => line.isNotEmpty && !line.startsWith('#'))
              .toList();
      int completed = 0;

      for (final segment in segmentUrls) {
        final segmentUrl = Uri.parse(url).resolve(segment).toString();
        if (_cancelMap.containsKey(url)) {
          final cancelToken = await _downloadManager.startDownload(
            segmentUrl,
            (_) {},
          );
          _cancelMap[url] = cancelToken;
          completed++;
          final progress = completed / segmentUrls.length;
          onProgress.call(progress);
          _streamController.add(
            DownloadData(DownloadStatus.downloading, url, progress),
          );
        } else {
          _streamController.add(
            DownloadData(
              DownloadStatus.canceled,
              url,
              completed / segmentUrls.length,
            ),
          );
          return;
        }
      }

      _streamController.add(DownloadData(DownloadStatus.completed, url, 1));
    } catch (e) {
      _streamController.add(DownloadData(DownloadStatus.failed, url, 0));
    }
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
