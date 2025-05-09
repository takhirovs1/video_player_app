import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:video_player_package/video_player_package.dart';

import '../../../../common/constants/app_colors.dart';
import '../../../../common/extensions/size_extension.dart';
import '../../../../common/utils/dimension.dart';
import '../../../home/data/models/video_model.dart';
import '../controllers/view_screen_controller.dart';
import '../widgets/view_richtext.dart';

class ViewScreen extends StatefulWidget {
  const ViewScreen({required this.videoModel, super.key});
  final VideoModel videoModel;

  @override
  _ViewScreenState createState() => _ViewScreenState();
}

class _ViewScreenState extends State<ViewScreen> with ViewScreenController {
  @override
  void initState() {
    super.initState();
    initializeController(widget.videoModel.url);
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: false,
    child: Scaffold(
      backgroundColor: AppColors.backgroundColor,
      appBar:
          isFullscreen
              ? null
              : AppBar(
                title: Text(
                  widget.videoModel.name,
                  style: const TextStyle(color: AppColors.red),
                ),
                backgroundColor: AppColors.backgroundColor,
                leading: BackButton(
                  color: AppColors.red,
                  onPressed: () {
                    context.pop();
                  },
                ),
              ),
      bottomNavigationBar:
          isFullscreen
              ? null
              : SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: ValueListenableBuilder<DownloadStatus>(
                    valueListenable: videoController.downloadStatus,
                    builder:
                        (context, status, _) => ValueListenableBuilder<double>(
                          valueListenable: videoController.progress,
                          builder: (context, progress, _) {
                            final isDownloading =
                                status == DownloadStatus.downloading;
                            final isCompleted =
                                status == DownloadStatus.completed;

                            return ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: getButtonColor(status),
                                fixedSize: Size(context.width * 0.85, 60),
                              ),
                              onPressed:
                                  isDownloading
                                      ? cancelDownload
                                      : (isCompleted
                                          ? removeDownload
                                          : downloadVideo),
                              child: Stack(
                                alignment: Alignment.center,
                                children: [
                                  if (isDownloading)
                                    Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        SizedBox(
                                          width: 40,
                                          height: 40,
                                          child: CircularProgressIndicator(
                                            value: progress,
                                            valueColor:
                                                const AlwaysStoppedAnimation<Color>(
                                                  Colors.white,
                                                ),
                                            strokeWidth: 3,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          '${(progress * 100).toStringAsFixed(0)}%',
                                          style: const TextStyle(color: Colors.white),
                                        ),
                                      ],
                                    ),
                                  if (!isDownloading)
                                    Text(
                                      getButtonText(status),
                                      style: const TextStyle(
                                        color: Colors.white,
                                      ),
                                    ),
                                ],
                              ),
                            );
                          },
                        ),
                  ),
                ),
              ),
      body: Column(
        children: [
          AspectRatio(
            aspectRatio: 16 / (isFullscreen ? 6.8 : 9),
            child: VideoPlayerWidget(
              controller: videoController,
              onFullscreenToggle: (value) => toggleFullscreen(),
            ),
          ),
          if (!isFullscreen)
            Expanded(
              child: ListView(
                padding: Dimension.pAll10,
                children: [
                  ViewRichtext(
                    mainText: 'Name: ',
                    text: widget.videoModel.name,
                  ),
                  Dimension.hBox10,
                  ViewRichtext(
                    mainText: 'Description: ',
                    text: widget.videoModel.description,
                  ),
                ],
              ),
            ),
        ],
      ),
    ),
  );
}
