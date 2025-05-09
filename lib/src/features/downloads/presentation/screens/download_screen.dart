import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player_package/video_player_package.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/utils/dimension.dart';
import '../../../../router/name_routes.dart';
import '../../../../services/local_source.dart';

class DownloadScreen extends StatefulWidget {
  const DownloadScreen({super.key});

  @override
  State<DownloadScreen> createState() => _DownloadScreenState();
}

class _DownloadScreenState extends State<DownloadScreen> {
  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: AppColors.backgroundColor,
    appBar: AppBar(
      title: const Text('Download Screen', style: TextStyle(color: AppColors.red)),
      backgroundColor: AppColors.backgroundColor,
    ),
    body: StreamBuilder(
      stream: context.read<VideoPlayerControllerInterfaceImpl>().statusStream(),
      builder: (context, snapshot) {
        final videos = LocalSource.getDownloadedVideos();
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            childAspectRatio: 1,
          ),
          itemCount: videos.length,
          itemBuilder: (context, index) {
            final video = videos.elementAt(index);
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
      },
    ),
  );
}
