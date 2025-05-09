import 'dart:async';
import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../common/core/screen_status.dart';
import '../../data/models/video_model.dart';
import '../../data/repository/video_repository.dart';

part 'video_state.dart';
part 'video_event.dart';

class VideoBloc extends Bloc<VideoEvent, VideoState> {
  VideoBloc({required this.videoRepository}) : super(VideoState.initial()) {
    on<GetVideoData>(_getVideoData);
  }

  final VideoRepository videoRepository;

  FutureOr<void> _getVideoData(GetVideoData event, Emitter<VideoState> emit) async {
    emit(state.copyWith(status: Status.loading));

    try {
      final videos = await videoRepository.fetchVideos();
      emit(state.copyWith(status: Status.success, videos: videos));
    } catch (e) {
      emit(state.copyWith(status: Status.error));
    }
  }
}
