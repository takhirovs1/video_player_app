import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

typedef ProgressCallback = void Function(double progress);

class DownloadManager {
  final Dio _dio = Dio();
  final Map<String, CancelToken> _cancelTokens = {};

  Future<String> startDownload(String url, ProgressCallback onProgress) async {
    final dir = await getApplicationDocumentsDirectory();
    final fileName = url.split('/').last;
    final savePath = '${dir.path}/$fileName';

    final cancelToken = CancelToken();
    _cancelTokens[url] = cancelToken;

    await _dio.download(
      url,
      savePath,
      onReceiveProgress: (received, total) {
        if (total != -1) {
          onProgress(received / total);
        }
      },
      cancelToken: cancelToken,
    );

    _cancelTokens.remove(url);
    return savePath;
  }

  void cancelDownload(String url) {
    if (_cancelTokens.containsKey(url)) {
      _cancelTokens[url]!.cancel();
      _cancelTokens.remove(url);
    }
  }

  Future<void> removeDownload(String path) async {
    final file = File(path);
    if (file.existsSync()) {
      await file.delete();
    }
  }

  Future<bool> fileExists(String path) async => File(path).existsSync();
}
