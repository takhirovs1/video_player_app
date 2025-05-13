// ignore_for_file: public_member_api_docs, sort_constructors_first
import 'dart:convert';

import 'package:equatable/equatable.dart';

class VideoModel extends Equatable {
  const VideoModel({required this.url, required this.name, required this.image, required this.description, this.path});

  factory VideoModel.fromJson(Map<String, Object?> json) => VideoModel(
    url: json['url'] as String,
    name: json['name'] as String,
    image: json['image'] as String,
    description: json['description'] as String,
    path: json['path'] as String?,
  );

  final String url;
  final String name;
  final String image;
  final String description;
  final String? path;

  VideoModel copyWith({String? url, String? name, String? image, String? description, String? path}) => VideoModel(
    url: url ?? this.url,
    name: name ?? this.name,
    image: image ?? this.image,
    description: description ?? this.description,
    path: path ?? this.path,
  );

  @override
  String toString() => '$url, $name, $image, $description,';

  Map<String, Object?> toJson() => <String, Object?>{
    'url': url,
    'name': name,
    'image': image,
    'description': description,
    'path': path,
  };

  @override
  List<Object?> get props => [url, name, image, description, path];
}
