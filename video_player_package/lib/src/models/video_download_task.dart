class VideoDownloadTask {
  final String url;
  String? localPath;
  double progress;
  bool isCompleted;
  bool isDownloading;
  bool isFailed;

  VideoDownloadTask({
    required this.url,
    this.localPath,
    this.progress = 0.0,
    this.isCompleted = false,
    this.isDownloading = false,
    this.isFailed = false,
  });
}
