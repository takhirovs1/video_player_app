import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:hls_downloader/hls_downloader.dart';
import 'package:video_player_package/src/download_manager.dart';
import 'package:video_player_package/video_player_package.dart';

enum DownloadStatus { notStarted, downloading, completed, canceled, failed }

typedef ProgressCallback = void Function(double progress);

abstract class VideoPlayerControllerInterface {
  const VideoPlayerControllerInterface();
  Stream<DownloadData> statusStream();
  Future<bool> isExist(String url);

  Future<void> startDownload({required String url, required ProgressCallback onProgress});

  Future<void> cancelDownload(String url);

  Future<void> removeDownload(String url);

  Future<void> dispose();

  Future<File?> getFile(String url);

  Future<DownloadData> getInitialData(String url);
}

class VideoPlayerControllerInterfaceImpl extends VideoPlayerControllerInterface {
  static final Map<String, CancelToken> _cancelMap = {};
  final DownloadManagerInterface _downloadManager;
  final HlsDownloader _hlsDownloader = HlsDownloader();
  final Map<String, String> _hlsIds = {}; // url -> downloadId
  final StreamController<DownloadData> _streamController;

  VideoPlayerControllerInterfaceImpl()
    : _downloadManager = DownloadManagerImpl(),
      _streamController = StreamController.broadcast();

  @override
  Stream<DownloadData> statusStream() => _streamController.stream;

  @override
  Future<void> cancelDownload(String url) async {
    if (_hlsIds.containsKey(url)) {
      // HLS pause/cancel not yet implemented natively; just emit canceled status.
      _hlsIds.remove(url);
      _streamController.add(DownloadData(DownloadStatus.canceled, url, 0));
      return;
    }

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
  Future<void> startDownload({required String url, required ProgressCallback onProgress}) async {
    // --- HLS (m3u8) branch  --------------------------------------------------
    if (url.toLowerCase().endsWith('.m3u8')) {
      // Native plugin
      final id = await _hlsDownloader.startDownload(url);
      // emit initial "downloading 0%" so UI shows progress indicator right away
      onProgress.call(0.0);
      _streamController.add(DownloadData(DownloadStatus.downloading, url, 0.0));
      _hlsIds[url] = id;

      _hlsDownloader.progressStream(id).listen((p) async {
        onProgress.call(p.percent);
        final path = await _hlsDownloader.localPath(id);
        _streamController.add(
          DownloadData(p.percent == 1 ? DownloadStatus.completed : DownloadStatus.downloading, url, p.percent, path),
        );
      });

      return;
    }

    // --- Default HTTP branch --------------------------------------------------
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
  Future<File?> getFile(String url) async {
    if (_hlsIds.containsKey(url)) {
      final local = await _hlsDownloader.localPath(_hlsIds[url]!); // helper you expose in plugin
      if (local != null) return File(local);
    }
    return await _downloadManager.file(url);
  }

  @override
  Future<DownloadData> getInitialData(String url) async {
    final file = await getFile(url);
    if (file != null) {
      return DownloadData(DownloadStatus.completed, url, 1);
    }
    return DownloadData(DownloadStatus.notStarted, url, 0);
  }
}
