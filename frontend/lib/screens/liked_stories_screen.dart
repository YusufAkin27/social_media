import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

class LikedStoriesScreen extends StatefulWidget {
  const LikedStoriesScreen({Key? key}) : super(key: key);

  @override
  _LikedStoriesScreenState createState() => _LikedStoriesScreenState();
}

class _LikedStoriesScreenState extends State<LikedStoriesScreen> {
  bool _isLoading = true;
  List<StoryItem> _stories = [];
  String? _errorMessage;
  int _page = 1;
  final int _pageSize = 20;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchLikedStories();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMorePages) {
      _loadMoreStories();
    }
  }

  Future<void> _fetchLikedStories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/stories/liked?page=$_page&pageSize=$_pageSize'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> storiesList = data['stories'] ?? [];
        final stories =
            storiesList.map((item) => StoryItem.fromJson(item)).toList();

        setState(() {
          _stories = stories;
          _isLoading = false;
          _hasMorePages = stories.length >= _pageSize;
          _page = 2; // İlk sayfa yüklendi, sonraki sayfa 2 olacak
        });
      } else {
        setState(() {
          _errorMessage =
              'Beğenilen hikayeler alınamadı: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMoreStories() async {
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/stories/liked?page=$_page&pageSize=$_pageSize'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> storiesList = data['stories'] ?? [];
        final stories =
            storiesList.map((item) => StoryItem.fromJson(item)).toList();

        setState(() {
          _stories.addAll(stories);
          _isLoadingMore = false;
          _hasMorePages = stories.length >= _pageSize;
          _page++;
        });
      } else {
        setState(() {
          _errorMessage =
              'Daha fazla hikaye yüklenemedi: ${response.statusCode}';
          _isLoadingMore = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
        _isLoadingMore = false;
      });
    }
  }

  Future<void> _unlikeStory(String storyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.post(
        Uri.parse('http://192.168.89.61:8080/v1/api/stories/$storyId/unlike'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _stories.removeWhere((story) => story.id == storyId);
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hikayeyi beğenmekten vazgeçtiniz'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Beğeni kaldırılamadı'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bağlantı hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  void _refreshStories() {
    setState(() {
      _page = 1;
      _stories = [];
    });
    _fetchLikedStories();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Beğenilen Hikayeler',
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshStories,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _errorMessage != null
              ? _buildErrorWidget()
              : _stories.isEmpty
                  ? _buildEmptyWidget()
                  : _buildStoriesList(),
    );
  }

  Widget _buildStoriesList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _stories.length + (_hasMorePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _stories.length) {
          return _buildLoadingMoreIndicator();
        }

        final story = _stories[index];
        return _buildStoryItem(story);
      },
    );
  }

  Widget _buildStoryItem(StoryItem story) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst bölüm - Kullanıcı bilgisi ve tarih
          ListTile(
            contentPadding:
                const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 4),
            leading: GestureDetector(
              onTap: () => Navigator.pushNamed(
                context,
                '/user-profile',
                arguments: {'userId': story.userId},
              ),
              child: CircleAvatar(
                radius: 20,
                backgroundColor: Colors.grey[800],
                backgroundImage: story.userProfilePhoto.isNotEmpty
                    ? CachedNetworkImageProvider(story.userProfilePhoto)
                    : null,
                child: story.userProfilePhoto.isEmpty
                    ? const Icon(Icons.person, color: Colors.white60)
                    : null,
              ),
            ),
            title: Text(
              story.userName,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: Text(
              timeago.format(story.createdAt, locale: 'tr'),
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: Colors.grey[850],
              onSelected: (value) {
                if (value == 'unlike') {
                  _unlikeStory(story.id);
                } else if (value == 'report') {
                  // Hikayeyi raporla
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'unlike',
                  child: ListTile(
                    leading:
                        Icon(Icons.remove_circle_outline, color: Colors.red),
                    title: Text('Beğenmekten Vazgeç',
                        style: TextStyle(color: Colors.white)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'report',
                  child: ListTile(
                    leading: Icon(Icons.flag_outlined, color: Colors.orange),
                    title:
                        Text('Raporla', style: TextStyle(color: Colors.white)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
              ],
            ),
          ),

          // Hikaye içeriği
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              story.content,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),

          // Hikaye görseli
          if (story.mediaUrl.isNotEmpty)
            GestureDetector(
              onTap: () {
                // Görsel büyük ekranda gösterme
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        FullScreenImage(imageUrl: story.mediaUrl),
                  ),
                );
              },
              child: ClipRRect(
                borderRadius: const BorderRadius.all(Radius.circular(8)),
                child: CachedNetworkImage(
                  imageUrl: story.mediaUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Shimmer.fromColors(
                    baseColor: Colors.grey[800]!,
                    highlightColor: Colors.grey[700]!,
                    child: Container(
                      width: double.infinity,
                      height: 200,
                      color: Colors.grey[800],
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    width: double.infinity,
                    height: 200,
                    color: Colors.grey[800],
                    child: const Icon(Icons.error, color: Colors.white60),
                  ),
                ),
              ),
            ),

          // Alt bölüm - İstatistikler
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(Icons.favorite, color: Colors.red[400], size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${story.likesCount}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.comment, color: Colors.blue[400], size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${story.commentsCount}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye,
                        color: Colors.white60, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${story.viewsCount}',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Beğenilen hikayeler yükleniyor...',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        color: Colors.blue,
        strokeWidth: 2,
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ??
                  'Beğenilen hikayeler yüklenirken bir hata oluştu.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshStories,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.auto_stories,
            color: Colors.white54,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz beğendiğin hikaye yok',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Hikayeleri beğendiğinde, onlara buradan kolayca erişebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/stories'),
            icon: const Icon(Icons.explore),
            label: const Text('Hikayeleri Keşfet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class StoryItem {
  final String id;
  final String userId;
  final String userName;
  final String userProfilePhoto;
  final String content;
  final String mediaUrl;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final DateTime createdAt;
  final bool isLiked;

  StoryItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfilePhoto,
    required this.content,
    required this.mediaUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.viewsCount,
    required this.createdAt,
    required this.isLiked,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userProfilePhoto: json['userProfilePhoto'] ?? '',
      content: json['content'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      viewsCount: json['viewsCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isLiked: json['isLiked'] ?? true,
    );
  }
}

class FullScreenImage extends StatelessWidget {
  final String imageUrl;

  const FullScreenImage({Key? key, required this.imageUrl}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          minScale: 0.5,
          maxScale: 3.0,
          child: CachedNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.contain,
            placeholder: (context, url) => const Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
            errorWidget: (context, url, error) => const Icon(
              Icons.error,
              color: Colors.white,
              size: 50,
            ),
          ),
        ),
      ),
    );
  }
}
