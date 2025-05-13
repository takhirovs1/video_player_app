import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart' as vp;
import 'video_player_controller.dart';

class VideoPlayerWidget extends StatefulWidget {
  final VideoPlayerControllerInterface controller;
  final ValueChanged<bool>? onFullscreenToggle;
  final String videoUrl;
  final String? path;

  const VideoPlayerWidget({
    super.key,
    required this.controller,
    required this.videoUrl,
    this.onFullscreenToggle,
    this.path,
  });

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  vp.VideoPlayerController? _videoController;
  bool _showControls = false;

  @override
  void initState() {
    super.initState();
    _initializeVideo();
    widget.controller.statusStream().listen((event) {
      if (event.url == widget.videoUrl && event.status == DownloadStatus.completed) {
        _initializeVideo();
      }
    });
  }

  Future<void> _initializeVideo() async {
    final file = await widget.controller.getFile(widget.videoUrl);
    if (widget.path != null) {
      log('widget.path: ${widget.path}');
      final File file = File(widget.path!);
      _videoController?.dispose();
      _videoController = vp.VideoPlayerController.file(file);
    } else if (file != null) {
      _videoController?.dispose();
      _videoController = vp.VideoPlayerController.file(file);
    } else {
      _videoController?.dispose();
      _videoController = vp.VideoPlayerController.network(widget.videoUrl);
    }

    await _videoController!.initialize();
    _videoController!.play();
    setState(() {});
  }

  @override
  void dispose() async {
    // _videoController?.pause();
    await _videoController?.dispose();
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    super.dispose();
    _videoController!.dispose();
  }

  String _format(Duration d) {
    two(int n) => n.toString().padLeft(2, '0');
    final m = two(d.inMinutes.remainder(60));
    final s = two(d.inSeconds.remainder(60));
    return '$m:$s';
  }

  void _seekRelative(int secs) {
    final pos = _videoController!.value.position;
    var target = pos + Duration(seconds: secs);
    final dur = _videoController!.value.duration;
    if (target < Duration.zero) target = Duration.zero;
    if (target > dur) target = dur;
    _videoController!.seekTo(target);
  }

  void _toggleControls() {
    setState(() => _showControls = true);
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => _showControls = false);
    });
  }

  void _toggleFullscreen() {
    final isPortrait = MediaQuery.of(context).orientation == Orientation.portrait;

    if (isPortrait) {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
      SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight]);
      widget.onFullscreenToggle?.call(true);
    } else {
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
      SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
      widget.onFullscreenToggle?.call(false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_videoController == null || !_videoController!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator.adaptive(backgroundColor: Colors.red));
    }

    final pos = _videoController!.value.position;
    final dur = _videoController!.value.duration;

    return GestureDetector(
      onTap: _toggleControls,
      child: AspectRatio(
        aspectRatio: _videoController!.value.aspectRatio,
        child: Stack(
          alignment: Alignment.center,
          children: [
            vp.VideoPlayer(_videoController!),
            if (_showControls)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.replay_10, color: Colors.white),
                    iconSize: 36,
                    onPressed: () => _seekRelative(-10),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: Icon(
                      _videoController!.value.isPlaying ? Icons.pause_circle_filled : Icons.play_circle_filled,
                      color: Colors.white,
                    ),
                    iconSize: 56,
                    onPressed: () async {
                      _videoController!.value.isPlaying
                          ? await _videoController!.pause()
                          : await _videoController!.play();
                      setState(() {});
                    },
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.forward_10, color: Colors.white),
                    iconSize: 36,
                    onPressed: () => _seekRelative(10),
                  ),
                ],
              ),
            if (_showControls)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Column(
                  children: [
                    vp.VideoProgressIndicator(_videoController!, allowScrubbing: true),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${_format(pos)}/${_format(dur)}', style: const TextStyle(color: Colors.white)),
                          IconButton(
                            icon: const Icon(Icons.fullscreen, color: Colors.white),
                            onPressed: _toggleFullscreen,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
