import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:timeago/timeago.dart' as timeago;

class ArchivedPostsScreen extends StatefulWidget {
  const ArchivedPostsScreen({Key? key}) : super(key: key);

  @override
  _ArchivedPostsScreenState createState() => _ArchivedPostsScreenState();
}

class _ArchivedPostsScreenState extends State<ArchivedPostsScreen> {
  bool _isLoading = true;
  List<PostItem> _posts = [];
  String? _errorMessage;
  int _page = 1;
  final int _pageSize = 10;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchArchivedPosts();
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
      _loadMorePosts();
    }
  }

  Future<void> _fetchArchivedPosts() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/api/posts/archived?page=$_page&pageSize=$_pageSize'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> postsList = data['posts'] ?? [];
        final posts = postsList.map((item) => PostItem.fromJson(item)).toList();

        setState(() {
          _posts = posts;
          _isLoading = false;
          _hasMorePages = posts.length >= _pageSize;
          _page = 2; // İlk sayfa yüklendi, sonraki sayfa 2 olacak
        });
      } else {
        setState(() {
          _errorMessage = 'Arşivlenen gönderiler alınamadı: ${response.statusCode}';
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

  Future<void> _loadMorePosts() async {
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/api/posts/archived?page=$_page&pageSize=$_pageSize'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> postsList = data['posts'] ?? [];
        final posts = postsList.map((item) => PostItem.fromJson(item)).toList();

        setState(() {
          _posts.addAll(posts);
          _isLoadingMore = false;
          _hasMorePages = posts.length >= _pageSize;
          _page++;
        });
      } else {
        setState(() {
          _errorMessage = 'Daha fazla gönderi yüklenemedi: ${response.statusCode}';
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

  Future<void> _unarchivePost(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.post(
        Uri.parse('http://localhost:8080/v1/api/posts/$postId/unarchive'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _posts.removeWhere((post) => post.id == postId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gönderi arşivden çıkarıldı'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gönderi arşivden çıkarılamadı'),
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

  Future<void> _deletePost(String postId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.delete(
        Uri.parse('http://localhost:8080/v1/api/posts/$postId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _posts.removeWhere((post) => post.id == postId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gönderi silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gönderi silinemedi'),
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

  void _refreshPosts() {
    setState(() {
      _page = 1;
      _posts = [];
    });
    _fetchArchivedPosts();
  }

  void _showDeleteConfirmation(String postId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text('Gönderiyi Sil', style: TextStyle(color: Colors.white)),
        content: const Text(
          'Bu gönderiyi kalıcı olarak silmek istediğinize emin misiniz? Bu işlem geri alınamaz.',
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
              _deletePost(postId);
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
        title: const Text('Arşivlenen Gönderiler', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshPosts,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _errorMessage != null
              ? _buildErrorWidget()
              : _posts.isEmpty
                  ? _buildEmptyWidget()
                  : _buildPostsList(),
    );
  }

  Widget _buildPostsList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _posts.length + (_hasMorePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _posts.length) {
          return _buildLoadingMoreIndicator();
        }
        
        final post = _posts[index];
        return _buildPostItem(post);
      },
    );
  }

  Widget _buildPostItem(PostItem post) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Üst bölüm - Kullanıcı bilgileri
          ListTile(
            contentPadding: const EdgeInsets.all(8),
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: Colors.grey[800],
              backgroundImage: post.userProfilePhoto.isNotEmpty
                  ? CachedNetworkImageProvider(post.userProfilePhoto)
                  : null,
              child: post.userProfilePhoto.isEmpty
                  ? const Icon(Icons.person, size: 24, color: Colors.white)
                  : null,
            ),
            title: Text(
              post.userName,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            subtitle: Text(
              timeago.format(post.createdAt, locale: 'tr'),
              style: TextStyle(color: Colors.grey[400], fontSize: 12),
            ),
            trailing: PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              color: Colors.grey[850],
              onSelected: (value) {
                if (value == 'unarchive') {
                  _unarchivePost(post.id);
                } else if (value == 'delete') {
                  _showDeleteConfirmation(post.id);
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
          
          // Başlık
          if (post.title.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                post.title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          
          // İçerik
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Text(
              post.content,
              style: const TextStyle(color: Colors.white, fontSize: 15),
            ),
          ),
          
          // Medya
          if (post.mediaUrls.isNotEmpty)
            GestureDetector(
              onTap: () {
                // Görseli tam ekran göster
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => FullScreenImage(imageUrl: post.mediaUrls[0]),
                  ),
                );
              },
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 8),
                child: ClipRRect(
                  borderRadius: const BorderRadius.all(Radius.circular(8)),
                  child: CachedNetworkImage(
                    imageUrl: post.mediaUrls[0],
                    fit: BoxFit.cover,
                    width: double.infinity,
                    height: 250,
                    placeholder: (context, url) => Shimmer.fromColors(
                      baseColor: Colors.grey[800]!,
                      highlightColor: Colors.grey[700]!,
                      child: Container(
                        width: double.infinity,
                        height: 250,
                        color: Colors.grey[800],
                      ),
                    ),
                    errorWidget: (context, url, error) => Container(
                      width: double.infinity,
                      height: 250,
                      color: Colors.grey[800],
                      child: const Icon(Icons.error, color: Colors.white60, size: 50),
                    ),
                  ),
                ),
              ),
            ),
          
          // Alt bölüm - Etkileşim istatistikleri
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
                      '${post.likesCount}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.comment, color: Colors.blue[400], size: 20),
                    const SizedBox(width: 4),
                    Text(
                      '${post.commentsCount}',
                      style: TextStyle(color: Colors.grey[400]),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye, color: Colors.white60, size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '${post.viewsCount}',
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
            'Arşivlenen gönderiler yükleniyor...',
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
              _errorMessage ?? 'Arşivlenen gönderiler yüklenirken bir hata oluştu.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshPosts,
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
            Icons.archive_outlined,
            color: Colors.white54,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Arşivlenen gönderin yok',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Arşivlediğin gönderiler burada görünecektir.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/home'),
            icon: const Icon(Icons.add_circle_outline),
            label: const Text('Ana Sayfaya Dön'),
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

class PostItem {
  final String id;
  final String userId;
  final String userName;
  final String userProfilePhoto;
  final String title;
  final String content;
  final List<String> mediaUrls;
  final int likesCount;
  final int commentsCount;
  final int viewsCount;
  final DateTime createdAt;
  final DateTime archivedAt;

  PostItem({
    required this.id,
    required this.userId,
    required this.userName,
    required this.userProfilePhoto,
    required this.title,
    required this.content,
    required this.mediaUrls,
    required this.likesCount,
    required this.commentsCount,
    required this.viewsCount,
    required this.createdAt,
    required this.archivedAt,
  });

  factory PostItem.fromJson(Map<String, dynamic> json) {
    List<String> mediaList = [];
    if (json['mediaUrls'] != null) {
      mediaList = List<String>.from(json['mediaUrls']);
    }

    return PostItem(
      id: json['id'] ?? '',
      userId: json['userId'] ?? '',
      userName: json['userName'] ?? '',
      userProfilePhoto: json['userProfilePhoto'] ?? '',
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      mediaUrls: mediaList,
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