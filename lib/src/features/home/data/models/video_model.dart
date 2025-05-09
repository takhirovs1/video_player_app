class VideoModel {
  VideoModel({required this.url, required this.name, required this.image, required this.description});

  factory VideoModel.fromJson(Map<String, Object?> json) => VideoModel(
    url: json['url'] as String,
    name: json['name'] as String,
    image: json['image'] as String,
    description: json['description'] as String,
  );

  final String url;
  final String name;
  final String image;
  final String description;

  VideoModel copyWith({String? url, String? name, String? image, String? description}) => VideoModel(
    url: url ?? this.url,
    name: name ?? this.name,
    image: image ?? this.image,
    description: description ?? this.description,
  );

  @override
  String toString() => '$url, $name, $image, $description,';
}
