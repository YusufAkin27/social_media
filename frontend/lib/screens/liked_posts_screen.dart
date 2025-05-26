import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/widgets/post_item.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

class LikedPostsScreen extends StatefulWidget {
  const LikedPostsScreen({Key? key}) : super(key: key);

  @override
  _LikedPostsScreenState createState() => _LikedPostsScreenState();
}

class _LikedPostsScreenState extends State<LikedPostsScreen>
    with SingleTickerProviderStateMixin {
  List<dynamic> _likedPosts = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMorePosts = true;
  bool _isLoadingMore = false;
  final int _postsPerPage = 10;
  final ScrollController _scrollController = ScrollController();

  // Tarih filtresi
  DateTime? _selectedDate;

  // View mode (list/grid)
  bool _isGridView = false;

  // Animation controller
  late AnimationController _animationController;

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
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
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

      // API endpoint
      String url = 'http://192.168.89.61:8080/v1/api/likes/posts';

      // Tarih filtresi eklenmiş mi?
      if (_selectedDate != null) {
        final formattedDate = DateFormat('dd.MM.yy').format(_selectedDate!);
        url =
            'http://192.168.89.61:8080/v1/api/likes/post/1/likes-after/$formattedDate';
      }

      // Sayfalandırma parametresi
      if (_currentPage > 0) {
        url += '?page=$_currentPage&size=$_postsPerPage';
      }

      final response = await http.get(
        Uri.parse(url),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseBody = json.decode(response.body);

        if (responseBody['success'] == true) {
          final posts = responseBody['data'] as List<dynamic>;

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
            _errorMessage = 'Veri alınamadı: ${responseBody['message']}';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'API hatası: ${response.statusCode}';
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

  void _showDateFilterDialog() {
    showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.indigoAccent,
              onPrimary: Colors.white,
              surface: Color(0xFF303030),
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: const Color(0xFF121212),
          ),
          child: child!,
        );
      },
    ).then((pickedDate) {
      if (pickedDate != null) {
        setState(() {
          _selectedDate = pickedDate;
          _currentPage = 0;
          _likedPosts = [];
        });
        _fetchLikedPosts();
      }
    });
  }

  void _clearDateFilter() {
    if (_selectedDate != null) {
      setState(() {
        _selectedDate = null;
        _currentPage = 0;
        _likedPosts = [];
      });
      _fetchLikedPosts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Beğenilen Gönderiler',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            )),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          // Tarih filtresi butonu
          IconButton(
            onPressed: _showDateFilterDialog,
            icon: Icon(
              Icons.calendar_month,
              color: _selectedDate != null ? Colors.indigoAccent : Colors.white,
            ),
            tooltip: 'Tarihe Göre Filtrele',
          ),

          // Filtreyi temizleme butonu
          if (_selectedDate != null)
            IconButton(
              onPressed: _clearDateFilter,
              icon: const Icon(Icons.filter_alt_off, color: Colors.white),
              tooltip: 'Filtreyi Temizle',
            ),

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
            tooltip: _isGridView ? 'Liste Görünümü' : 'Izgara Görünümü',
          ),
        ],
      ),
      body: Column(
        children: [
          // Aktif filtre gösterimi
          if (_selectedDate != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                border: Border(
                  bottom: BorderSide(color: Colors.grey[800]!, width: 1),
                ),
              ),
              child: Row(
                children: [
                  const Icon(Icons.filter_list,
                      color: Colors.indigoAccent, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${DateFormat('dd.MM.yyyy').format(_selectedDate!)} tarihinden sonraki gönderiler',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                  const Spacer(),
                  GestureDetector(
                    onTap: _clearDateFilter,
                    child:
                        const Icon(Icons.close, color: Colors.white, size: 18),
                  ),
                ],
              ),
            ),

          // Ana içerik
          Expanded(
            child: _isLoading && _currentPage == 0
                ? _buildLoadingState()
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _likedPosts.isEmpty
                        ? _buildEmptyState()
                        : _buildPostsContent(),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigoAccent,
        onPressed: _showDateFilterDialog,
        child: const Icon(Icons.filter_alt, color: Colors.white),
        tooltip: 'Tarihe Göre Filtrele',
      ),
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
          if (_selectedDate != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                '${DateFormat('dd.MM.yyyy').format(_selectedDate!)} tarihinden sonra',
                style: TextStyle(
                  color: Colors.indigoAccent,
                  fontSize: 14,
                ),
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
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
              _selectedDate != null
                  ? '${DateFormat('dd.MM.yyyy').format(_selectedDate!)} Tarihinden Sonra Beğeni Yok'
                  : 'Henüz Hiç Beğeni Yok',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              _selectedDate != null
                  ? 'Bu tarihten sonra beğendiğiniz içerik bulunmamaktadır. Farklı bir tarih seçin veya filtreyi kaldırın.'
                  : 'Beğendiğiniz gönderiler burada görünecek. Keşfet\'e gidip içerikleri keşfedin ve beğenmeye başlayın!',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_selectedDate != null)
                  ElevatedButton.icon(
                    onPressed: _clearDateFilter,
                    icon: const Icon(Icons.filter_alt_off),
                    label: const Text('Filtreyi Kaldır'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      textStyle: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                if (_selectedDate == null)
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/home');
                    },
                    icon: const Icon(Icons.explore),
                    label: const Text('Keşfet'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.indigoAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 15),
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

        // PostItem widget'ını güncellenmiş veri modeline göre ayarla
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: _buildEnhancedPostItem(post),
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

  Widget _buildEnhancedPostItem(Map<String, dynamic> post) {
    // Gönderi içeriği (fotoğraf veya video) - yeni data modeli için uyarlandı
    List<String> contentUrls = [];
    if (post['content'] != null && post['content'] is List) {
      contentUrls = List<String>.from(post['content']);
    }

    return Card(
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: Colors.grey[900],
      elevation: 4,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Gönderi sahibi bilgisi
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Profil fotoğrafı
                GestureDetector(
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/user_profile',
                      arguments: {'username': post['username']},
                    );
                  },
                  child: CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: post['profilePhoto'] != null
                        ? CachedNetworkImageProvider(post['profilePhoto'])
                        : null,
                    child: post['profilePhoto'] == null
                        ? const Icon(Icons.person,
                            size: 24, color: Colors.white)
                        : null,
                  ),
                ),
                const SizedBox(width: 12),
                // Kullanıcı adı ve zaman
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            '/user_profile',
                            arguments: {'username': post['username']},
                          );
                        },
                        child: Text(
                          post['username'] ?? 'Anonim',
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          if (post['location'] != null &&
                              post['location'].toString().isNotEmpty)
                            Row(
                              children: [
                                const Icon(Icons.location_on,
                                    size: 12, color: Colors.white70),
                                const SizedBox(width: 4),
                                Text(
                                  post['location'],
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 12,
                                  ),
                                ),
                                const SizedBox(width: 8),
                              ],
                            ),
                          Text(
                            post['howMoneyMinutesAgo'] ?? '',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Seçenekler butonu
                IconButton(
                  icon: const Icon(Icons.more_horiz, color: Colors.white70),
                  onPressed: () {
                    // Gönderi ayarları menüsü
                  },
                ),
              ],
            ),
          ),

          // Gönderi içeriği (fotoğraf/video)
          if (contentUrls.isNotEmpty)
            Container(
              constraints: const BoxConstraints(
                maxHeight: 400,
              ),
              width: double.infinity,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: PageView.builder(
                      itemCount: contentUrls.length,
                      itemBuilder: (context, index) {
                        return CachedNetworkImage(
                          imageUrl: contentUrls[index],
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[850],
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.indigoAccent),
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[850],
                            child: const Center(
                              child: Icon(Icons.error_outline,
                                  color: Colors.white54),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // Çoklu fotoğraf göstergesi
                  if (contentUrls.length > 1)
                    Positioned(
                      top: 12,
                      right: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          '1/${contentUrls.length}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

          // Gönderi açıklaması
          if (post['description'] != null &&
              post['description'].toString().isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(
                post['description'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                ),
              ),
            ),

          // Etiketlenen kişiler
          if (post['tagAPerson'] != null &&
              post['tagAPerson'] is List &&
              (post['tagAPerson'] as List).isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              child: Wrap(
                spacing: 8,
                children: (post['tagAPerson'] as List).map<Widget>((tag) {
                  return GestureDetector(
                    onTap: () {
                      // Etiketlenen kişinin profiline git
                      Navigator.pushNamed(
                        context,
                        '/user_profile',
                        arguments: {'username': tag},
                      );
                    },
                    child: Text(
                      '@$tag',
                      style: const TextStyle(
                        color: Colors.indigoAccent,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

          // İstatistik ve etkileşim düğmeleri
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.favorite,
                      color: Colors.red,
                      size: 24,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.mode_comment_outlined,
                      color: Colors.white70,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.send_outlined,
                      color: Colors.white70,
                      size: 22,
                    ),
                    Spacer(),
                    Icon(
                      Icons.bookmark_border,
                      color: Colors.white70,
                      size: 22,
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                // Beğeni sayısı
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    '${post['like'] ?? 0} beğenme',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Yorum sayısı
                if ((post['comment'] ?? 0) > 0)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        '${post['comment']} yorum görüntüle',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGridItemCard(Map<String, dynamic> post) {
    // Gönderi içeriği (fotoğraf veya video) - yeni data modeli için uyarlandı
    List<String> contentUrls = [];
    if (post['content'] != null && post['content'] is List) {
      contentUrls = List<String>.from(post['content']);
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
          if (contentUrls.isNotEmpty)
            GestureDetector(
              onTap: () {
                // Gönderi detayına gitme işlevi
                Navigator.pushNamed(context, '/post_detail',
                    arguments: {'post': post});
              },
              child: Stack(
                children: [
                  Hero(
                    tag: 'post_image_${post['postId']}',
                    child: CachedNetworkImage(
                      imageUrl: contentUrls.first,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      height: 200,
                      placeholder: (context, url) => Container(
                        height: 200,
                        color: Colors.grey[800],
                        child: const Center(
                          child: CircularProgressIndicator(
                            valueColor:
                                AlwaysStoppedAnimation<Color>(Colors.white54),
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

                  // Çoklu fotoğraf göstergesi
                  if (contentUrls.length > 1)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.7),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          Icons.photo_library,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                ],
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
                      backgroundImage: post['profilePhoto'] != null &&
                              post['profilePhoto'].toString().isNotEmpty
                          ? CachedNetworkImageProvider(post['profilePhoto'])
                          : null,
                      child: post['profilePhoto'] == null ||
                              post['profilePhoto'].toString().isEmpty
                          ? const Icon(Icons.person,
                              size: 16, color: Colors.white)
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

                // Gönderi açıklaması
                if (post['description'] != null &&
                    post['description'].toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    post['description'],
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
                          '${post['like'] ?? 0}',
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
                          '${post['comment'] ?? 0}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      post['howMoneyMinutesAgo'] ?? '',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 10,
                        fontStyle: FontStyle.italic,
                      ),
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
