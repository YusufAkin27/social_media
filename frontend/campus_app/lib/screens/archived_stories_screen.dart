import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

class ArchivedStoriesScreen extends StatefulWidget {
  const ArchivedStoriesScreen({Key? key}) : super(key: key);

  @override
  _ArchivedStoriesScreenState createState() => _ArchivedStoriesScreenState();
}

class _ArchivedStoriesScreenState extends State<ArchivedStoriesScreen> {
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
    _fetchArchivedStories();
    _scrollController.addListener(_scrollListener);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_scrollListener);
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollListener() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoading &&
        !_isLoadingMore &&
        _hasMorePages) {
      _loadMoreStories();
    }
  }

  Future<void> _fetchArchivedStories() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/api/stories/archived?page=$_page&pageSize=$_pageSize'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> storiesList = data['stories'] ?? [];
        final stories = storiesList.map((item) => StoryItem.fromJson(item)).toList();

        setState(() {
          _stories = stories;
          _isLoading = false;
          _hasMorePages = stories.length >= _pageSize;
          _page = 2; // İlk sayfa yüklendi, sonraki sayfa 2 olacak
        });
      } else {
        setState(() {
          _errorMessage = 'Arşivlenen hikayeler alınamadı: ${response.statusCode}';
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
        Uri.parse('http://localhost:8080/v1/api/stories/archived?page=$_page&pageSize=$_pageSize'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> storiesList = data['stories'] ?? [];
        final stories = storiesList.map((item) => StoryItem.fromJson(item)).toList();

        setState(() {
          _stories.addAll(stories);
          _isLoadingMore = false;
          _hasMorePages = stories.length >= _pageSize;
          _page++;
        });
      } else {
        setState(() {
          _errorMessage = 'Daha fazla hikaye yüklenemedi: ${response.statusCode}';
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

  Future<void> _unarchiveStory(String storyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.post(
        Uri.parse('http://localhost:8080/v1/api/stories/$storyId/unarchive'),
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
            content: Text('Hikaye arşivden çıkarıldı'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hikaye arşivden çıkarılamadı'),
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

  Future<void> _deleteStory(String storyId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.delete(
        Uri.parse('http://localhost:8080/v1/api/stories/$storyId'),
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
            content: Text('Hikaye silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Hikaye silinemedi'),
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
    _fetchArchivedStories();
  }

  void _showDeleteConfirmation(String storyId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Hikayeyi Sil', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bu hikayeyi kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: Colors.white70)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteStory(storyId);
            },
            child: const Text('Sil', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Arşivlenen Hikayeler', style: TextStyle(color: Colors.white)),
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
          // Üst bölüm - Tarih ve işlemler
          ListTile(
            contentPadding: const EdgeInsets.only(left: 16, right: 8, top: 8),
            title: Row(
              children: [
                const Icon(Icons.history, size: 16, color: Colors.grey),
                const SizedBox(width: 8),
                Text(
                  'Arşivlenme: ${timeago.format(story.archivedAt, locale: 'tr')}',
                  style: TextStyle(color: Colors.grey[400], fontSize: 12),
                ),
              ],
            ),
            subtitle: Text(
              'Oluşturulma: ${timeago.format(story.createdAt, locale: 'tr')}',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: Colors.grey[850],
              onSelected: (value) {
                if (value == 'unarchive') {
                  _unarchiveStory(story.id);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(story.id);
                }
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'unarchive',
                  child: ListTile(
                    leading: Icon(Icons.unarchive, color: Colors.blue),
                    title: Text('Arşivden Çıkar', style: TextStyle(color: Colors.white)),
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                  ),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete, color: Colors.red),
                    title: Text('Sil', style: TextStyle(color: Colors.white)),
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
                    builder: (context) => FullScreenImage(imageUrl: story.mediaUrl),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
                    const Icon(Icons.remove_red_eye, color: Colors.white60, size: 18),
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
            'Arşivlenen hikayeler yükleniyor...',
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
              _errorMessage ?? 'Arşivlenen hikayeler yüklenirken bir hata oluştu.',
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
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
            Icons.history_outlined,
            color: Colors.white54,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Arşivlenen hikayen yok',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Arşivlediğin hikayeler burada görünecektir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/stories'),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Hikayeler'),
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
  final String content;
  final String mediaUrl;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime archivedAt;

  StoryItem({
    required this.id,
    required this.content,
    required this.mediaUrl,
    required this.likesCount,
    required this.commentsCount,
    required this.viewsCount,
    required this.createdAt,
    required this.archivedAt,
  });

  factory StoryItem.fromJson(Map<String, dynamic> json) {
    return StoryItem(
      id: json['id'] ?? '',
      content: json['content'] ?? '',
      mediaUrl: json['mediaUrl'] ?? '',
      likesCount: json['likesCount'] ?? 0,
      commentsCount: json['commentsCount'] ?? 0,
      viewsCount: json['viewsCount'] ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      archivedAt: json['archivedAt'] != null
          ? DateTime.parse(json['archivedAt'])
          : DateTime.now(),
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