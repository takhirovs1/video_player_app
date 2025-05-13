import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../features/home/data/models/video_model.dart';

sealed class LocalSource {
  static SharedPreferences? _preferences;

  static SharedPreferences get preferences {
    assert(_preferences != null, 'Error');
    return _preferences!;
  }

  static Future<void> init() async {
    _preferences ??= await SharedPreferences.getInstance();
  }

  static List<VideoModel> getDownloadedVideos() {
    final list = preferences.getStringList('videos') ?? [];
    final result = list.map((e) => VideoModel.fromJson((jsonDecode(e) as Map).cast<String, Object?>())).toList();
    return result;
  }

  static VideoModel? getSingleDownloadedVideo(String url) {
    final list = getDownloadedVideos();
    return list.firstWhereOrNull((e) => e.url == url);
  }

  static Future<void> _setVideos(List<VideoModel> videos) async {
    await preferences.setStringList('videos', videos.map((e) => jsonEncode(e.toJson())).toList());
  }

  static Future<void> saveVideo(VideoModel video) async {
    final allVideos = getDownloadedVideos();
    await _setVideos([...allVideos, video]);
  }

  static Future<void> deleteVideo(VideoModel video) async {
    final allVideos = getDownloadedVideos();
    await _setVideos(allVideos..remove(video));
  }

  static Future<void> clear() async => await preferences.clear();
}
