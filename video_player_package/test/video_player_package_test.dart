import 'package:flutter_test/flutter_test.dart';
import 'package:video_player_package/video_player_package.dart';

void main() {
  group('VideoDownloadTask', () {
    test('should initialize with correct default values', () {
      final task = VideoDownloadTask(url: 'https://example.com/video.mp4');

      expect(task.url, 'https://example.com/video.mp4');
      expect(task.localPath, isNull);
      expect(task.progress, 0.0);
      expect(task.isCompleted, isFalse);
      expect(task.isDownloading, isFalse);
      expect(task.isFailed, isFalse);
    });
  });
}
