import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';

typedef ProgressCallback = void Function(double progress);

abstract class DownloadManagerInterface {
  Future<CancelToken> startDownload(String url, ProgressCallback onProgress);
  Future<File?> file(String url);
  Future<void> removeDownload(String url);
  Future<Directory> get saveDirectory;
}

class DownloadManagerImpl implements DownloadManagerInterface {
  final Dio _dio;

  DownloadManagerImpl() : _dio = Dio();

  @override
  Future<File?> file(String url) async {
    final filePath = (await saveDirectory).path + url.getFileName;
    final file = File(filePath);
    if (await file.exists()) {
      return file;
    }
    return null;
  }

  @override
  Future<void> removeDownload(String url) async {
    final fileDir = await file(url);
    await fileDir?.delete();
  }

  @override
  Future<Directory> get saveDirectory async {
    final temp = await getApplicationDocumentsDirectory();
    final Directory saveDir = Directory('${temp.path}/Downloads');
    if (!(await saveDir.exists())) {
      await saveDir.create(recursive: true);
    }
    return saveDir;
  }

  @override
  Future<CancelToken> startDownload(
    String url,
    ProgressCallback onProgress,
  ) async {
    final cancelToken = CancelToken();

    _dio
        .download(
          url,
          (_) async => (await saveDirectory).path + url.getFileName,
          onReceiveProgress: (received, total) {
            if (total != -1) {
              onProgress(received / total);
            }
          },
          cancelToken: cancelToken,
        )
        .then((value) => onProgress(1));

    return cancelToken;
  }
}

extension on String {
  String get getFileName => split('/').last;
}
