import 'package:flutter/material.dart';
import 'package:social_media/widgets/media_kit_player.dart';
import 'package:social_media/enhanced_video_player.dart';
import 'package:social_media/utils/video_helper.dart';

/// Evrensel video oynatıcı widget
/// Öncelikle MediaKit'i kullanmaya çalışır, hata durumunda EnhancedVideoPlayer'a geri döner
class UniversalVideoPlayer extends StatefulWidget {
  final String videoUrl;
  final bool autoPlay;
  final bool looping;
  final bool showControls;
  final double aspectRatio;
  final BoxFit fit;
  final bool allowFullScreen;
  final bool allowMuting;
  final bool showOptions;

  const UniversalVideoPlayer({
    Key? key,
    required this.videoUrl,
    this.autoPlay = false,
    this.looping = false,
    this.showControls = true,
    this.aspectRatio = 16 / 9,
    this.fit = BoxFit.contain,
    this.allowFullScreen = true,
    this.allowMuting = true,
    this.showOptions = true,
  }) : super(key: key);

  @override
  State<UniversalVideoPlayer> createState() => _UniversalVideoPlayerState();
}

class _UniversalVideoPlayerState extends State<UniversalVideoPlayer> {
  bool _useMediaKit = true;
  String _normalizedUrl = '';
  bool _isLoading = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _normalizedUrl = VideoHelper.normalizeVideoUrl(widget.videoUrl);
  }
  
  @override
  void didUpdateWidget(UniversalVideoPlayer oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.videoUrl != widget.videoUrl) {
      _normalizedUrl = VideoHelper.normalizeVideoUrl(widget.videoUrl);
      
      // Reset to MediaKit when URL changes
      setState(() {
        _useMediaKit = true;
        _errorMessage = null;
      });
    }
  }
  
  void _handleMediaKitError() {
    if (mounted) {
      setState(() {
        _useMediaKit = false;
        _isLoading = true;
      });
      
      // Add a slight delay to allow for the UI to update
      Future.delayed(Duration(milliseconds: 300), () {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      });
    }
  }

  void _handleEnhancedPlayerError(String error) {
    if (mounted) {
      setState(() {
        _errorMessage = error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Boş URL kontrolü
    if (_normalizedUrl.isEmpty) {
      return const Center(
        child: Text('Geçerli video URL\'si yok', 
          style: TextStyle(color: Colors.white),
        ),
      );
    }
    
    // Hata durumu kontrolü
    if (_errorMessage != null) {
      return _buildErrorWidget();
    }
    
    // Yükleme durumu
    if (_isLoading) {
      return _buildLoadingWidget();
    }
    
    // MediaKit kullanıcıysa
    if (_useMediaKit) {
      return MediaKitPlayer(
        videoUrl: _normalizedUrl,
        autoPlay: widget.autoPlay,
        looping: widget.looping,
        showControls: widget.showControls,
        aspectRatio: widget.aspectRatio,
        fit: widget.fit,
        allowFullScreen: widget.allowFullScreen,
        allowMuting: widget.allowMuting,
        showOptions: widget.showOptions,
        onError: _handleMediaKitError,
      );
    }
    
    // Yedek olarak EnhancedVideoPlayer
    return EnhancedVideoPlayer(
      videoUrl: _normalizedUrl,
      autoPlay: widget.autoPlay,
      looping: widget.looping,
      showControls: widget.showControls,
      aspectRatio: widget.aspectRatio,
      fit: widget.fit,
      allowFullScreen: widget.allowFullScreen,
      allowMuting: widget.allowMuting,
      showOptions: widget.showOptions,
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
              'Video oynatıcı değiştiriliyor...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      ),
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
          if (_errorMessage != null && _errorMessage!.isNotEmpty)
            Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.white70, fontSize: 12),
              textAlign: TextAlign.center,
            ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              setState(() {
                _useMediaKit = true;
                _errorMessage = null;
              });
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue),
            child: const Text('Yeniden Dene'),
          ),
        ],
      ),
    );
  }
} 