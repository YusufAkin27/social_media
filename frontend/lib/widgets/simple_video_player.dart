import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:social_media/utils/video_helper.dart';
import 'package:flutter/cupertino.dart';
import 'package:social_media/theme/app_theme.dart';

class SimpleVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool muted;
  final BoxFit fit;
  final VoidCallback? onTap;
  
  const SimpleVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.autoPlay = true,
    this.looping = true,
    this.muted = true,
    this.fit = BoxFit.cover,
    this.onTap,
  }) : super(key: key);

  @override
  State<SimpleVideoPlayer> createState() => _SimpleVideoPlayerState();
}

class _SimpleVideoPlayerState extends State<SimpleVideoPlayer> with SingleTickerProviderStateMixin {
  late VideoPlayerController _controller;
  bool _isInitialized = false;
  bool _isPlaying = false;
  bool _hasError = false;
  bool _showPlayPauseOverlay = false;
  bool _isMuted = true;
  bool _showVolumeSlider = false;
  double _volume = 1.0;
  late AnimationController _volumeAnimationController;
  late Animation<double> _volumeAnimation;
  
  @override
  void initState() {
    super.initState();
    _isMuted = widget.muted;
    _initializeVideoPlayer();
    
    // Initialize volume animation controller
    _volumeAnimationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    _volumeAnimation = CurvedAnimation(
      parent: _volumeAnimationController,
      curve: Curves.easeOutCubic,
    );
  }
  
  Future<void> _initializeVideoPlayer() async {
    try {
      String normalizedUrl = VideoHelper.normalizeVideoUrl(widget.videoUrl);
      
      _controller = VideoPlayerController.network(
        normalizedUrl,
        videoPlayerOptions: VideoPlayerOptions(mixWithOthers: true),
      );

      await _controller.initialize();
      
      if (_isMuted) {
        _controller.setVolume(0);
      } else {
        _controller.setVolume(1.0);
      }
      
      if (widget.autoPlay) {
        _controller.play();
        _isPlaying = true;
      }
      
      if (widget.looping) {
        _controller.setLooping(true);
      }
      
      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    } catch (e) {
      print('Video player initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
        });
      }
    }
  }
  
  void _togglePlayPause() {
    setState(() {
      if (_controller.value.isPlaying) {
        _controller.pause();
        _isPlaying = false;
      } else {
        _controller.play();
        _isPlaying = true;
      }
      
      // Show overlay briefly
      _showPlayPauseOverlay = true;
    });
    
    // Hide overlay after a short delay
    Future.delayed(const Duration(milliseconds: 800), () {
      if (mounted) {
        setState(() {
          _showPlayPauseOverlay = false;
        });
      }
    });
  }
  
  void _toggleMute() {
    setState(() {
      _isMuted = !_isMuted;
      
      if (_isMuted) {
        _controller.setVolume(0.0);
        _showVolumeSlider = false;
      } else {
        _controller.setVolume(_volume);
        _showVolumeSlider = true;
        
        // Hide volume slider after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _showVolumeSlider) {
            setState(() {
              _showVolumeSlider = false;
            });
          }
        });
      }
      
      // Play animation
      _volumeAnimationController.reset();
      _volumeAnimationController.forward();
      
      // Show feedback to user
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _isMuted ? 'Ses kapatıldı' : 'Ses açıldı',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: AppColors.cardBackground,
          duration: Duration(seconds: 1),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    });
  }
  
  void _changeVolume(double value) {
    setState(() {
      _volume = value;
      _controller.setVolume(_volume);
      
      // Reset the auto-hide timer for volume slider
      Future.delayed(const Duration(seconds: 3), () {
        if (mounted && _showVolumeSlider) {
          setState(() {
            _showVolumeSlider = false;
          });
        }
      });
    });
  }
  
  void _showVolumeControl() {
    if (!_isMuted) {
      setState(() {
        _showVolumeSlider = true;
        
        // Hide volume slider after 3 seconds
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted && _showVolumeSlider) {
            setState(() {
              _showVolumeSlider = false;
            });
          }
        });
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    _volumeAnimationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return Container(
        color: Colors.black,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(CupertinoIcons.exclamationmark_circle, 
                color: AppColors.primaryText, 
                size: 40
              ),
              SizedBox(height: 8),
              Text(
                'Video yüklenemedi',
                style: TextStyle(color: AppColors.primaryText),
              ),
            ],
          ),
        ),
      );
    }

    if (!_isInitialized) {
      return Container(
        color: Colors.black,
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.accent,
            strokeWidth: 2,
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: widget.onTap ?? _togglePlayPause,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Video player
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),
          
          // Play/pause overlay
          if (_showPlayPauseOverlay)
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                shape: BoxShape.circle,
              ),
              padding: EdgeInsets.all(12),
              child: Icon(
                _isPlaying ? CupertinoIcons.pause : CupertinoIcons.play_fill,
                color: Colors.white,
                size: 30,
              ),
            ),
          
          // Muted indicator
          Positioned(
            bottom: 10,
            right: 10,
            child: GestureDetector(
              onTap: _toggleMute,
              onLongPress: _showVolumeControl,
              child: AnimatedBuilder(
                animation: _volumeAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: 1.0 + (_volumeAnimation.value * 0.2),
                    child: Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: _isMuted 
                            ? Colors.red.withOpacity(_volumeAnimation.value * 0.5) 
                            : Colors.green.withOpacity(_volumeAnimation.value * 0.5),
                          width: 1.5 * _volumeAnimation.value,
                        ),
                      ),
                      child: Icon(
                        _isMuted 
                          ? CupertinoIcons.volume_mute
                          : _volume > 0.5 
                              ? CupertinoIcons.volume_up
                              : CupertinoIcons.volume_down,
                        color: _isMuted 
                          ? Colors.white.withOpacity(0.8)
                          : Colors.white,
                        size: 18,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
          
          // Volume slider
          if (_showVolumeSlider && !_isMuted)
            Positioned(
              bottom: 10,
              left: 10,
              right: 50,
              child: Container(
                height: 40,
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                      CupertinoIcons.volume_down,
                      color: Colors.white,
                      size: 16,
                    ),
                    Expanded(
                      child: SliderTheme(
                        data: SliderThemeData(
                          trackHeight: 2,
                          activeTrackColor: Colors.white,
                          inactiveTrackColor: Colors.white.withOpacity(0.3),
                          thumbColor: Colors.white,
                          thumbShape: RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: RoundSliderOverlayShape(overlayRadius: 12),
                        ),
                        child: Slider(
                          value: _volume,
                          min: 0.0,
                          max: 1.0,
                          onChanged: _changeVolume,
                        ),
                      ),
                    ),
                    Icon(
                      CupertinoIcons.volume_up,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
} 