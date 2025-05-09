import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/core/screen_status.dart';
import '../../../../common/utils/dimension.dart';
import '../../../../router/name_routes.dart';
import '../bloc/video_bloc.dart';
import '../../data/repository/video_repository.dart';

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late VideoBloc _videoBloc;

  @override
  void initState() {
    super.initState();
    _videoBloc = VideoBloc(videoRepository: VideoRepositoryImpl());
    _videoBloc.add(GetVideoData());
  }

  @override
  void dispose() {
    _videoBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => BlocProvider.value(
    value: _videoBloc,
    child: Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar: AppBar(
        backgroundColor: AppColors.backgroundColor,
        title: const Text('Movie Tube', style: TextStyle(color: AppColors.red)),
      ),
      body: BlocBuilder<VideoBloc, VideoState>(
        builder: (context, state) {
          if (state.status == Status.loading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state.status == Status.success && state.videos != null) {
            return GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: state.videos!.length,
              itemBuilder: (context, index) {
                final video = state.videos![index];
                return Card(
                  elevation: 4,
                  color: AppColors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: InkWell(
                    onTap: () {
                      context.pushNamed(Routes.view, extra: video);
                    },
                    borderRadius: Dimension.rAll16,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: Dimension.rTop16,
                          child: Image.network(video.image, height: 100, width: double.infinity, fit: BoxFit.cover),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            video.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.white),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(
                            video.description,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12, color: AppColors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          } else {
            return const Center(child: Text('Xatolik yuz berdi', style: TextStyle(color: AppColors.white)));
          }
        },
      ),
    ),
  );
}
