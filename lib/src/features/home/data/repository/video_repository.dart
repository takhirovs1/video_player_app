import 'dart:convert';

import 'package:flutter/services.dart';

import '../models/video_model.dart';

abstract class VideoRepository {
  Future<List<VideoModel>> fetchVideos();
}

class VideoRepositoryImpl implements VideoRepository {
  @override
  Future<List<VideoModel>> fetchVideos() async {
    final response = await rootBundle.loadString('assets/json/video_api.json');
    final data = json.decode(response) as List;
    return data.map((json) => VideoModel.fromJson(json as Map<String, Object?>)).toList();
  }
}
