part of 'video_bloc.dart';

class VideoState extends Equatable {
  const VideoState({required this.status, this.videos});

  factory VideoState.initial() => const VideoState(status: Status.initial);

  final Status status;
  final List<VideoModel>? videos;

  VideoState copyWith({Status? status, List<VideoModel>? videos}) =>
      VideoState(status: status ?? this.status, videos: videos ?? this.videos);

  @override
  List<Object?> get props => [status, videos];
}
