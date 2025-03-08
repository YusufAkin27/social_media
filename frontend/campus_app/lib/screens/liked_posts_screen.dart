import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/widgets/post_item.dart';
import 'package:social_media/services/likeService.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;

class LikedPostsScreen extends StatefulWidget {
  const LikedPostsScreen({Key? key}) : super(key: key);

  @override
  _LikedPostsScreenState createState() => _LikedPostsScreenState();
}

class _LikedPostsScreenState extends State<LikedPostsScreen> with SingleTickerProviderStateMixin {
  List<dynamic> _likedPosts = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMorePosts = true;
  bool _isLoadingMore = false;
  final int _postsPerPage = 10;
  final ScrollController _scrollController = ScrollController();
  
  // View mode (list/grid)
  bool _isGridView = false;
  
  // Animation controller
  late AnimationController _animationController;
  
  // LikeService instance'ı
  final LikeService _likeService = LikeService();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _fetchLikedPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMorePosts) {
      _loadMorePosts();
    }
  }

  Future<void> _fetchLikedPosts() async {
    if (_isLoading && _currentPage > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      // LikeService kullanarak beğenilen gönderileri al
      final response = await _likeService.getUserLikedPosts(
        accessToken, 
        page: _currentPage, 
        size: _postsPerPage
      );

      if (response.isSuccess) {
        final posts = response.data ?? [];
        
        setState(() {
          if (_currentPage == 0) {
            _likedPosts = posts;
          } else {
            _likedPosts.addAll(posts);
          }
          
          _hasMorePosts = posts.length >= _postsPerPage;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Beğenilen gönderiler yüklenirken bir hata oluştu: ${response.message}';
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
    if (_isLoadingMore || !_hasMorePosts) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    _currentPage++;
    await _fetchLikedPosts();
    
    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _refreshPosts() async {
    _currentPage = 0;
    _hasMorePosts = true;
    await _fetchLikedPosts();
    return Future.value();
  }
  
  void _toggleViewMode() {
    setState(() {
      _isGridView = !_isGridView;
      if (_isGridView) {
        _animationController.forward();
      } else {
        _animationController.reverse();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Beğenilen Gönderiler', 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          )
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Görünüm modu toggle butonu
          IconButton(
            onPressed: _toggleViewMode,
            icon: AnimatedBuilder(
              animation: _animationController,
              builder: (context, child) {
                return Transform.rotate(
                  angle: _animationController.value * math.pi / 2,
                  child: Icon(
                    _isGridView ? Icons.view_list : Icons.grid_view,
                    color: Colors.white,
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: _isLoading && _currentPage == 0
          ? _buildLoadingState()
          : _errorMessage != null
              ? _buildErrorWidget()
              : _likedPosts.isEmpty
                  ? _buildEmptyState()
                  : _buildPostsContent(),
    );
  }
  
  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Kalp animasyonu
          Lottie.network(
            'https://assets5.lottiefiles.com/packages/lf20_qiftnlad.json',
            width: 120,
            height: 120,
          ),
          const SizedBox(height: 20),
          const Text(
            'Beğenilen gönderiler yükleniyor...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: Colors.redAccent.withOpacity(0.2),
                borderRadius: BorderRadius.circular(40),
              ),
              child: const Icon(
                Icons.error_outline,
                color: Colors.redAccent,
                size: 40,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bir Hata Oluştu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage ?? 'Bilinmeyen bir hata oluştu',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _refreshPosts,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Boş durum animasyonu
            Lottie.network(
              'https://assets10.lottiefiles.com/packages/lf20_wdgehvtj.json',
              width: 200,
              height: 200,
            ),
            const SizedBox(height: 24),
            Text(
              'Henüz Hiç Beğeni Yok',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Text(
              'Beğendiğiniz gönderiler burada görünecek. Keşfet\'e gidip içerikleri keşfedin ve beğenmeye başlayın!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushReplacementNamed(context, '/home');
              },
              icon: const Icon(Icons.explore),
              label: const Text('Keşfet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 15),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsContent() {
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: Colors.indigoAccent,
      backgroundColor: Colors.grey[900],
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isGridView ? _buildGridView() : _buildListView(),
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      key: const ValueKey<String>('list_view'),
      controller: _scrollController,
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: _likedPosts.length + (_hasMorePosts ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _likedPosts.length) {
          return _buildLoadingIndicator();
        }
        
        // Direkt olarak map'i kullan
        Map<String, dynamic> post = _likedPosts[index];
        
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: PostItem(post: post),
        );
      },
    );
  }

  Widget _buildGridView() {
    return MasonryGridView.count(
      key: const ValueKey<String>('grid_view'),
      controller: _scrollController,
      crossAxisCount: 2,
      mainAxisSpacing: 8,
      crossAxisSpacing: 8,
      padding: const EdgeInsets.all(8),
      itemCount: _likedPosts.length + (_hasMorePosts ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _likedPosts.length) {
          return _buildLoadingIndicator();
        }
        
        // Direkt olarak map'i kullan
        Map<String, dynamic> post = _likedPosts[index];
        
        // Grid view için özel bir kart tasarımı
        return _buildGridItemCard(post);
      },
    );
  }
  
  Widget _buildGridItemCard(Map<String, dynamic> post) {
    // Gönderi fotoğrafları (varsa)
    List<String> photoUrls = [];
    if (post['photos'] != null && post['photos'] is List && (post['photos'] as List).isNotEmpty) {
      photoUrls = (post['photos'] as List).map((photo) => photo['url'] as String).toList();
    }
    
    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey[900],
      elevation: 2,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gönderi resmi
          if (photoUrls.isNotEmpty)
            GestureDetector(
              onTap: () {
                // Gönderi detayına gitme işlevi
                Navigator.pushNamed(
                  context, 
                  '/post_detail',
                  arguments: {'post': post}
                );
              },
              child: Hero(
                tag: 'post_image_${post['postId']}',
                child: CachedNetworkImage(
                  imageUrl: photoUrls.first,
                  fit: BoxFit.cover,
                  width: double.infinity,
                  height: 200,
                  placeholder: (context, url) => Container(
                    height: 200,
                    color: Colors.grey[800],
                    child: const Center(
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                      ),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    height: 200,
                    color: Colors.grey[800],
                    child: const Icon(Icons.error, color: Colors.white54),
                  ),
                ),
              ),
            ),
          
          // Kullanıcı bilgisi ve içerik özeti
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Kullanıcı adı
                Row(
                  children: [
                    CircleAvatar(
                      radius: 14,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: post['profilePhoto'] != null && post['profilePhoto'].toString().isNotEmpty
                          ? CachedNetworkImageProvider(post['profilePhoto'])
                          : null,
                      child: post['profilePhoto'] == null || post['profilePhoto'].toString().isEmpty
                          ? const Icon(Icons.person, size: 16, color: Colors.white)
                          : null,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        post['username'] ?? 'Anonim',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                
                // Gönderi metni
                if (post['text'] != null && post['text'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    post['text'],
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
                
                // İstatistikler (beğeni, yorum, vb.)
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.favorite,
                          color: Colors.redAccent,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post['likeCount'] ?? 0}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        const Icon(
                          Icons.comment,
                          color: Colors.white54,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '${post['commentCount'] ?? 0}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
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
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 24),
      alignment: Alignment.center,
      child: const Column(
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
            strokeWidth: 2,
          ),
          SizedBox(height: 16),
          Text(
            'Daha fazla içerik yükleniyor...',
            style: TextStyle(
              color: Colors.white54,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }
} 