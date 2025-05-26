import 'package:flutter/material.dart';
import 'package:social_media/widgets/pod_video_player.dart';
import 'package:social_media/utils/video_helper.dart';
import 'package:social_media/widgets/simple_video_player.dart';

class VideoPlayerWidget extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double aspectRatio;
  final BoxFit fit;
  final bool isInFeed;
  final bool muted;

  const VideoPlayerWidget({
    Key? key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.contain,
    this.isInFeed = false,
    this.muted = true,
  }) : super(key: key);

  @override
  State<VideoPlayerWidget> createState() => _VideoPlayerWidgetState();
}

class _VideoPlayerWidgetState extends State<VideoPlayerWidget> {
  late String _normalizedUrl;
  
  @override
  void initState() {
    super.initState();
    _normalizedUrl = VideoHelper.normalizeVideoUrl(widget.videoUrl);
  }
  
  @override
  void didUpdateWidget(VideoPlayerWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _normalizedUrl = VideoHelper.normalizeVideoUrl(widget.videoUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    // For feed videos, use the simpler player with autoplay and loop
    if (widget.isInFeed) {
      return AspectRatio(
        aspectRatio: widget.aspectRatio,
        child: SimpleVideoPlayer(
          videoUrl: _normalizedUrl,
          autoPlay: true,
          looping: true,
          muted: widget.muted,
          fit: widget.fit,
          onTap: () {
            // Navigate to post details when tapped in feed
            // This will be handled by the parent widget
          },
        ),
      );
    }
    
    // For detailed view, use the full-featured player
    return AspectRatio(
      aspectRatio: widget.aspectRatio,
      child: PodVideoPlayerWidget(
        videoUrl: _normalizedUrl,
        autoPlay: widget.autoPlay,
        isLooping: widget.looping,
        showControls: widget.showControls,
      ),
    );
  }
} 