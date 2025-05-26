import 'dart:io';
import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:social_media/utils/video_helper.dart';
import 'dart:math';

class EnhancedVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double aspectRatio;
  final BoxFit fit;
  final bool allowFullScreen;
  final bool allowMuting;
  final bool showOptions;

  const EnhancedVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.autoPlay = true,
    this.looping = false,
    this.showControls = true,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.contain,
    this.allowFullScreen = true,
    this.allowMuting = true,
    this.showOptions = true,
  }) : super(key: key);

  @override
  State<EnhancedVideoPlayer> createState() => _EnhancedVideoPlayerState();
}

class _EnhancedVideoPlayerState extends State<EnhancedVideoPlayer> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isInitialized = false;
  bool _hasError = false;
  String _errorMessage = '';
  bool _isBuffering = false;
  String _appVersion = '';
  String _deviceInfo = '';
  bool _isAndroid10OrAbove = false;
  String _videoType = 'unknown';

  @override
  void initState() {
    super.initState();
    _getDeviceInfo();
    _enableWakeLock();
    _initializePlayer();
  }

  Future<void> _getDeviceInfo() async {
    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      setState(() {
        _appVersion = packageInfo.version;
      });
      
      if (Platform.isAndroid) {
        final androidSdkInt = await _getAndroidSdkVersion();
        setState(() {
          _isAndroid10OrAbove = androidSdkInt >= 29; // Android 10 is API level 29
          _deviceInfo = 'Android SDK $androidSdkInt';
        });
      } else if (Platform.isIOS) {
        setState(() {
          _deviceInfo = 'iOS ${Platform.operatingSystemVersion}';
        });
      }
    } catch (e) {
      print('Device info error: $e');
    }
  }

  Future<int> _getAndroidSdkVersion() async {
    try {
      return int.parse(Platform.operatingSystemVersion.split(' ').last);
    } catch (e) {
      return 0;
    }
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
    });

    try {
      if (widget.videoUrl.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video URL boş!';
          _isBuffering = false;
        });
        return;
      }
      
      // Video URL'yi normalize et
      final normalizedUrl = VideoHelper.normalizeVideoUrl(widget.videoUrl);
      
      // Video dosyası erişilebilir mi kontrol et
      if (normalizedUrl.startsWith('http') && 
          !await VideoHelper.isVideoUrlAccessible(normalizedUrl)) {
        setState(() {
          _hasError = true;
          _errorMessage = 'Video URL erişilebilir değil! URL: ${normalizedUrl.substring(0, min(30, normalizedUrl.length))}...';
          _isBuffering = false;
        });
        return;
      }

      // Video türünü tespit et
      if (normalizedUrl.startsWith('http')) {
        _videoType = await VideoHelper.detectVideoStreamType(normalizedUrl);
        print('Video type detected: $_videoType');
      }

      await _disposeCurrentControllers();

      if (normalizedUrl.startsWith('http')) {
        _videoPlayerController = VideoPlayerController.network(
          normalizedUrl,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
          httpHeaders: {
            'User-Agent': 'SocialMediaApp/$_appVersion ($_deviceInfo)',
            'Range': 'bytes=0-',  // Kısmi içerik destekler
            'Accept': '*/*',
            'Accept-Encoding': 'gzip, deflate, br',
            'Connection': 'keep-alive',
          },
        );
      } else if (normalizedUrl.startsWith('asset')) {
        _videoPlayerController = VideoPlayerController.asset(
          normalizedUrl.replaceFirst('asset', ''),
        );
      } else if (File(normalizedUrl).existsSync()) {
        _videoPlayerController = VideoPlayerController.file(
          File(normalizedUrl),
        );
      } else {
        // Son çare olarak URL olarak kabul et
        _videoPlayerController = VideoPlayerController.network(
          normalizedUrl,
          videoPlayerOptions: VideoPlayerOptions(
            mixWithOthers: false,
            allowBackgroundPlayback: false,
          ),
          httpHeaders: {
            'User-Agent': 'SocialMediaApp/$_appVersion ($_deviceInfo)',
            'Range': 'bytes=0-',
          },
        );
      }

      // Video yüklenme hatalarını dinle
      _videoPlayerController.addListener(_onPlayerListener);

      // Önce initialize bekleyelim
      await _videoPlayerController.initialize().timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw Exception('Video yükleme zaman aşımına uğradı!');
        },
      );

      final customControls = _isAndroid10OrAbove ? 
        const MaterialControls() :  // Android 10+ için Material tasarımlı kontroller
        const CupertinoControls(  // Diğer sürümler için Cupertino kontroller
          backgroundColor: Color.fromRGBO(41, 41, 41, 0.7),
          iconColor: Color.fromARGB(255, 200, 200, 200),
        );

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        aspectRatio: _videoPlayerController.value.aspectRatio != 0.0 ? 
                     _videoPlayerController.value.aspectRatio : 16/9,
        allowFullScreen: widget.allowFullScreen,
        showControls: widget.showControls,
        allowMuting: widget.allowMuting,
        allowPlaybackSpeedChanging: widget.showOptions,
        customControls: customControls,
        placeholder: Container(
          color: Colors.black,
          child: const Center(
            child: CircularProgressIndicator(
              color: Colors.white,
            ),
          ),
        ),
        errorBuilder: (context, errorMessage) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, color: Colors.red, size: 42),
                SizedBox(height: 8),
                Text(
                  'Video oynatılamıyor',
                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 4),
                Text(
                  errorMessage,
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 4),
                Text(
                  'URL: ${normalizedUrl.substring(0, min(30, normalizedUrl.length))}...',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
                Text(
                  'Cihaz: $_deviceInfo, Video Türü: $_videoType, Uygulama: $_appVersion',
                  style: TextStyle(color: Colors.white70, fontSize: 10),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _retryInitialization,
                  child: Text('Tekrar Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                  ),
                ),
              ],
            ),
          );
        },
      );

      if (mounted) {
        setState(() {
          _isInitialized = true;
          _isBuffering = false;
        });
      }
    } catch (e) {
      print("Video player initialization error: $e");
      if (mounted) {
        setState(() {
          _hasError = true;
          _errorMessage = e.toString();
          _isBuffering = false;
        });
      }
    }
  }

  void _onPlayerListener() {
    final controller = _videoPlayerController;
    
    if (!mounted) return;

    // Buffering durumunu kontrol et
    final bool isBuffering = controller.value.isBuffering;
    if (_isBuffering != isBuffering) {
      setState(() {
        _isBuffering = isBuffering;
      });
    }

    // Video hata durumunu kontrol et
    if (controller.value.hasError && !_hasError) {
      setState(() {
        _hasError = true;
        _errorMessage = controller.value.errorDescription ?? 'Bilinmeyen video hatası';
      });
    }
  }

  void _retryInitialization() {
    setState(() {
      _hasError = false;
      _errorMessage = '';
    });
    _initializePlayer();
  }

  Future<void> _disposeCurrentControllers() async {
    if (_chewieController != null) {
      _chewieController!.dispose();
      _chewieController = null;
    }
    
    if (_videoPlayerController != null) {
      await _videoPlayerController.dispose();
    }
  }

  @override
  void dispose() {
    _videoPlayerController.removeListener(_onPlayerListener);
    _disposeCurrentControllers();
    _disableWakeLock();
    VideoHelper.clearVideoCache();
    super.dispose();
  }

  @override
  void didUpdateWidget(EnhancedVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // URL değiştiyse videoyu yeniden yükle
    if (widget.videoUrl != oldWidget.videoUrl) {
      _initializePlayer();
    }
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
        AspectRatio(
          aspectRatio: widget.aspectRatio != 0 
              ? widget.aspectRatio 
              : _videoPlayerController.value.aspectRatio,
          child: Chewie(controller: _chewieController!),
        ),
        if (_isBuffering)
          Positioned.fill(
            child: Container(
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
      color: Colors.black,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, color: Colors.red, size: 42),
              SizedBox(height: 8),
              Text(
                'Video oynatılamadı',
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 8),
              if (_errorMessage.isNotEmpty)
                Container(
                  padding: EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _errorMessage,
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                    textAlign: TextAlign.center,
                  ),
                ),
              SizedBox(height: 16),
              Text(
                'Cihaz: $_deviceInfo, Video Türü: $_videoType, Uygulama: $_appVersion',
                style: TextStyle(color: Colors.white70, fontSize: 10),
              ),
              SizedBox(height: 16),
              ElevatedButton(
                onPressed: _retryInitialization,
                child: Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingWidget() {
    return Container(
      color: Colors.black,
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
            SizedBox(height: 16),
            Text(
              'Video hazırlanıyor...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
} 