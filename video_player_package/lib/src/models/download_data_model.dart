import 'package:video_player_package/video_player_package.dart';

class DownloadData {
  final String url;
  final DownloadStatus status;
  final double progress;

  const DownloadData(this.status, this.url, this.progress);
}
