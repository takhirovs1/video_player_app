import 'package:video_player_package/video_player_package.dart';

class DownloadData {
  final String url;
  final DownloadStatus status;
  final double progress;
  final String? path;

  const DownloadData(this.status, this.url, this.progress, [this.path]);
}
