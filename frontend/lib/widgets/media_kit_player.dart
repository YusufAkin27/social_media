import 'package:flutter/material.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:social_media/utils/video_helper.dart';
import 'package:social_media/enhanced_video_player.dart';
import 'package:flutter/foundation.dart';

/// Daha güçlü bir video oynatıcı widget
/// MediaKit kullanarak çok daha fazla video formatını destekler
class MediaKitPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double aspectRatio;
  final BoxFit fit;
  final bool allowFullScreen;
  final bool allowMuting;
  final bool showOptions;
  final Color controlsColor;
  final Color backgroundColor;
  final Function? onError;

  const MediaKitPlayer({
    Key? key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = true,
    this.showControls = true,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.contain,
    this.allowFullScreen = true,
    this.allowMuting = true,
    this.showOptions = true,
    this.controlsColor = Colors.white,
    this.backgroundColor = Colors.black,
    this.onError,
  }) : super(key: key);

  @override
  State<MediaKitPlayer> createState() => _MediaKitPlayerState();
}

class _MediaKitPlayerState extends State<MediaKitPlayer> {
  late final Player _player;
  late final VideoController _controller;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isBuffering = true;
  String _videoFormat = 'unknown';
  bool _isRetrying = false;
  int _retryCount = 0;
  final int _maxRetries = 2;

  @override
  void initState() {
    super.initState();
    _enableWakeLock();
    _initializePlayer();
  }

  void _enableWakeLock() async {
    try {
      await WakelockPlus.enable();
    } catch (e) {
      print('Wakelock error: $e');
    }
  }

  void _disableWakeLock() async {
    try {
      await WakelockPlus.disable();
    } catch (e) {
      print('Wakelock disable error: $e');
    }
  }

  void _initializePlayer() async {
    setState(() {
      _isBuffering = true;
      _hasError = false;
      _errorMessage = '';
    });

    try {
      if (widget.videoUrl.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video URL boş!';
          _isBuffering = false;
        });
        if (widget.onError != null) {
          widget.onError!();
        }
        return;
      }

      // Normalize URL and detect format
      final normalizedUrl = VideoHelper.normalizeVideoUrl(widget.videoUrl);
      if (normalizedUrl.startsWith('http')) {
        try {
          _videoFormat = await VideoHelper.detectVideoStreamType(normalizedUrl);
          print('Video format detected: $_videoFormat');
        } catch (e) {
          print('Format detection error: $e');
        }
      }

      // Create player and controller instances
      _player = Player();
      _controller = VideoController(_player);

      // Configure player
      await _player.setPlaylistMode(widget.looping ? PlaylistMode.loop : PlaylistMode.single);
      await _player.setVolume(100); // Default volume
      
      // Set up custom headers when needed
      final Map<String, String> headers = {
        'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/96.0.4664.110 Safari/537.36',
        'Accept': '*/*',
        'Accept-Encoding': 'gzip, deflate, br',
        'Connection': 'keep-alive',
      };
      
      // Open the media source
      await _player.open(Media(normalizedUrl, httpHeaders: headers));
      
      // Auto-play if requested
      if (widget.autoPlay) {
        _player.play();
      }
      
      // Listen for player state changes
      _player.stream.buffering.listen((buffering) {
        if (mounted && _isBuffering != buffering) {
          setState(() {
            _isBuffering = buffering;
          });
        }
      });

      _player.stream.error.listen((error) {
        print('MediaKit player error: $error');
        if (mounted && !_hasError) {
          setState(() {
            _hasError = true;
            _errorMessage = error;
          });
          
          if (!_isRetrying && _retryCount < _maxRetries) {
            _retryInitializationAutomatically();
          } else if (widget.onError != null) {
            widget.onError!();
          }
        }
      });

      _player.stream.playing.listen((playing) {
        print('MediaKit player playing: $playing');
      });

      // Listen for end of the media
      _player.stream.completed.listen((completed) {
        if (completed && !widget.looping) {
          print('Video playback completed');
        }
      });

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isBuffering = false;
          _retryCount = 0; // Reset retry count on successful initialization
        });
      }
      
    } catch (e) {
      print('MediaKit player initialization error: $e');
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isBuffering = false;
        });
        
        if (!_isRetrying && _retryCount < _maxRetries) {
          _retryInitializationAutomatically();
        } else if (widget.onError != null) {
          widget.onError!();
        }
      }
    }
  }

  void _retryInitializationAutomatically() {
    _retryCount++;
    _isRetrying = true;
    
    print('Automatically retrying initialization (attempt $_retryCount)');
    
    Future.delayed(Duration(seconds: 2), () {
      if (mounted) {
        _cleanupPlayer();
        _initializePlayer();
        _isRetrying = false;
      }
    });
  }

  void _cleanupPlayer() {
    try {
      if (_player.state.playing) {
        _player.pause();
      }
      _player.dispose();
    } catch (e) {
      print('Error during player cleanup: $e');
    }
  }

  void _retryInitialization() {
    _retryCount = 0;
    _cleanupPlayer();
    _initializePlayer();
  }

  @override
  void didUpdateWidget(MediaKitPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // If the URL changed, reinitialize the player
    if (widget.videoUrl != oldWidget.videoUrl) {
      _cleanupPlayer();
      _initializePlayer();
    }
  }

  @override
  void dispose() {
    _cleanupPlayer();
    _disableWakeLock();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_hasError) {
      return _buildErrorWidget();
    }

    if (!_isInitialized) {
      return _buildLoadingWidget();
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(8.0),
          child: AspectRatio(
            aspectRatio: widget.aspectRatio,
            child: Video(
              controller: _controller,
              controls: widget.showControls ? MaterialVideoControls : null,
              fit: widget.fit,
            ),
          ),
        ),
        if (_isBuffering)
          const Positioned.fill(
            child: ColoredBox(
              color: Colors.black54,
              child: Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildErrorWidget() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.black87,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 42),
          const SizedBox(height: 8),
          const Text(
            'Video oynatılamıyor',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          if (_errorMessage.isNotEmpty)
            Text(
              _errorMessage,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 4),
          Text(
            'Format: $_videoFormat, URL: ${widget.videoUrl.length > 30 ? widget.videoUrl.substring(0, 30) + "..." : widget.videoUrl}',
            style: const TextStyle(color: Colors.white70, fontSize: 10),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _retryInitialization,
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Tekrar Dene'),
          ),
          if (widget.onError != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: TextButton(
                onPressed: () {
                  if (widget.onError != null) {
                    widget.onError!();
                  }
                },
                child: const Text('Yedek oynatıcıyı dene', 
                  style: TextStyle(color: Colors.amberAccent),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Video yükleniyor...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
} 