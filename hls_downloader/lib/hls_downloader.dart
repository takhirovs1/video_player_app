import 'package:flutter/services.dart';

/// Simple typed progress holder for HLS downloads
class DownloadProgress {
  final String id;
  final double percent;
  const DownloadProgress(this.id, this.percent);
}

/// Public API for the hls_downloader plugin.
///
/// Communicates with native iOS / Android code via MethodChannel & EventChannel.
class HlsDownloader {
  static const MethodChannel _channel = MethodChannel('hls_downloader');

  /// Start background download for an HLS (.m3u8) video [url].
  ///
  /// Returns a unique download id generated natively.
  Future<String> startDownload(String url) async {
    final id =
        await _channel.invokeMethod<String>('startDownload', {'url': url});
    if (id == null) {
      throw PlatformException(
          code: 'NULL_ID',
          message: 'Native side returned null download id for $url');
    }
    return id;
  }

  /// Progress stream (0.0 – 1.0) for a given [downloadId].
  Stream<DownloadProgress> progressStream(String downloadId) {
    return EventChannel('hls_downloader/progress_$downloadId')
        .receiveBroadcastStream()
        .map((e) => DownloadProgress(downloadId, (e as num).toDouble()));
  }

  /// Local file path for a completed download (if exists).
  Future<String?> localPath(String downloadId) async {
    return _channel.invokeMethod<String>('localPath', {'id': downloadId});
  }
}
