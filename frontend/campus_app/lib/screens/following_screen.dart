import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:social_media/models/followed_user_dto.dart';
import 'package:social_media/services/followRelationService.dart';
import 'package:dio/dio.dart';

class FollowingScreen extends StatefulWidget {
  const FollowingScreen({Key? key}) : super(key: key);

  @override
  _FollowingScreenState createState() => _FollowingScreenState();
}

class _FollowingScreenState extends State<FollowingScreen> {
  bool _isLoading = true;
  List<FollowedUserDTO> _following = [];
  String? _errorMessage;
  int _page = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  final FollowRelationService _followService = FollowRelationService(Dio());

  @override
  void initState() {
    super.initState();
    _fetchFollowing();
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
      _loadMoreFollowing();
    }
  }

  Future<void> _fetchFollowing() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await _followService.getFollowing(accessToken, _page);
      
      if (response.isSuccess) {
        setState(() {
          _following = response.data ?? [];
          _isLoading = false;
          _hasMorePages = (response.data?.length ?? 0) > 0;
          _page = 2; // İlk sayfa yüklendi, sonraki sayfa 2 olacak
        });
      } else {
        setState(() {
          _errorMessage = 'Takip edilenler alınamadı: ${response.message}';
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

  Future<void> _loadMoreFollowing() async {
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await _followService.getFollowing(accessToken, _page);
      
      if (response.isSuccess) {
        final newFollowing = response.data ?? [];
        
        setState(() {
          _following.addAll(newFollowing);
          _isLoadingMore = false;
          _hasMorePages = newFollowing.isNotEmpty;
          _page++;
        });
      } else {
        setState(() {
          _errorMessage = 'Daha fazla takip edilen yüklenemedi: ${response.message}';
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

  Future<void> _unfollowUser(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await _followService.removeFollowing(accessToken, userId);

      if (response.isSuccess) {
        setState(() {
          _following.removeWhere((user) => user.id == userId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Takibi bıraktın'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Takipten çıkarılamadı: ${response.message}'),
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

  Future<void> _searchFollowing(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await _followService.searchFollowing(accessToken, query, 1);
      
      if (response.isSuccess) {
        setState(() {
          _following = response.data ?? [];
          _isLoading = false;
          _hasMorePages = false; // Arama sonuçlarında sayfalama yapmıyoruz
        });
      } else {
        setState(() {
          _errorMessage = 'Arama yapılamadı: ${response.message}';
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

  void _refreshFollowing() {
    setState(() {
      _page = 1;
      _following = [];
    });
    _fetchFollowing();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Takip Edilenler', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _FollowingSearchDelegate(
                  onSearch: _searchFollowing,
                  onClear: _refreshFollowing,
                ),
              );
            },
            tooltip: 'Ara',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshFollowing,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _errorMessage != null
              ? _buildErrorWidget()
              : _following.isEmpty
                  ? _buildEmptyWidget()
                  : _buildFollowingList(),
    );
  }

  Widget _buildFollowingList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _following.length + (_hasMorePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _following.length) {
          return _buildLoadingMoreIndicator();
        }
        
        final user = _following[index];
        return _buildFollowingItem(user);
      },
    );
  }

  Widget _buildFollowingItem(FollowedUserDTO user) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(8),
        leading: GestureDetector(
          onTap: () => Navigator.pushNamed(
            context,
            '/user-profile',
            arguments: {'userId': user.id},
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[800],
            backgroundImage: user.profilePhotoUrl != null && user.profilePhotoUrl!.isNotEmpty
                ? CachedNetworkImageProvider(user.profilePhotoUrl!)
                : null,
            child: user.profilePhotoUrl == null || user.profilePhotoUrl!.isEmpty
                ? const Icon(Icons.person, color: Colors.white60)
                : null,
          ),
        ),
        title: Text(
          '${user.fullName}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '@${user.username}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            if (user.bio != null && user.bio!.isNotEmpty)
              Text(
                user.bio!,
                style: TextStyle(color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: OutlinedButton(
          onPressed: () => _unfollowUser(user.id),
          style: OutlinedButton.styleFrom(
            side: BorderSide(color: Colors.grey[700]!),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            foregroundColor: Colors.white,
          ),
          child: const Text('Takip Ediliyor'),
        ),
        onTap: () => Navigator.pushNamed(
          context,
          '/user-profile',
          arguments: {'userId': user.id},
        ),
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
            'Takip edilenler yükleniyor...',
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
              _errorMessage ?? 'Takip edilenler yüklenirken bir hata oluştu.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshFollowing,
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
            Icons.group_outlined,
            color: Colors.white54,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz kimseyi takip etmiyorsun',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'İnsanları takip ederek onların içeriklerini\nana sayfanda görüntüleyebilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/discover-people'),
            icon: const Icon(Icons.search),
            label: const Text('Kişileri Keşfet'),
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

// Arama işlemleri için delegate sınıfı
class _FollowingSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;
  final VoidCallback onClear;

  _FollowingSearchDelegate({required this.onSearch, required this.onClear});

  @override
  String get searchFieldLabel => 'Takip edilenlerde ara...';

  @override
  TextStyle? get searchFieldStyle => const TextStyle(color: Colors.white);

  @override
  ThemeData appBarTheme(BuildContext context) {
    return ThemeData(
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.black,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      textTheme: const TextTheme(
        titleLarge: TextStyle(color: Colors.white),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
        border: InputBorder.none,
      ),
      textSelectionTheme: const TextSelectionThemeData(
        cursorColor: Colors.white,
      ),
      scaffoldBackgroundColor: Colors.black,
    );
  }

  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          if (query.isEmpty) {
            close(context, '');
          } else {
            query = '';
            showSuggestions(context);
          }
        },
      )
    ];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, '');
        onClear(); // Aramadan çıkınca listeyi yenile
      },
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.trim().length < 2) {
      return Center(
        child: Text(
          'En az 2 karakter girin.',
          style: TextStyle(color: Colors.grey[400], fontSize: 16),
        ),
      );
    }

    onSearch(query.trim());
    close(context, query);
    return Container(); // Sonuçlar ana ekranda gösterilecek
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.trim().length < 2) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.search, color: Colors.white54, size: 60),
            const SizedBox(height: 16),
            Text(
              'Kullanıcı adı veya isimle arayın',
              style: TextStyle(color: Colors.grey[400], fontSize: 16),
            ),
          ],
        ),
      );
    }

    // Anlık arama önerilerini döndürmek için kullanılabilir
    // Şu an için boş bırakıldı
    return Container();
  }
} 