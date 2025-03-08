import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:social_media/models/followed_user_dto.dart';
import 'package:social_media/services/followRelationService.dart';
import 'package:dio/dio.dart';

class FollowersScreen extends StatefulWidget {
  const FollowersScreen({Key? key}) : super(key: key);

  @override
  _FollowersScreenState createState() => _FollowersScreenState();
}

class _FollowersScreenState extends State<FollowersScreen> {
  bool _isLoading = true;
  List<FollowedUserDTO> _followers = [];
  String? _errorMessage;
  int _page = 1;
  bool _hasMorePages = true;
  bool _isLoadingMore = false;
  final ScrollController _scrollController = ScrollController();
  final FollowRelationService _followService = FollowRelationService(Dio());

  @override
  void initState() {
    super.initState();
    _fetchFollowers();
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
      _loadMoreFollowers();
    }
  }

  Future<void> _fetchFollowers() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await _followService.getFollowers(accessToken, _page);
      
      if (response.isSuccess) {
        setState(() {
          _followers = response.data ?? [];
          _isLoading = false;
          _hasMorePages = (response.data?.length ?? 0) > 0;
          _page = 2; // İlk sayfa yüklendi, sonraki sayfa 2 olacak
        });
      } else {
        setState(() {
          _errorMessage = 'Takipçiler alınamadı: ${response.message}';
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

  Future<void> _loadMoreFollowers() async {
    if (_isLoadingMore || !_hasMorePages) return;

    setState(() {
      _isLoadingMore = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await _followService.getFollowers(accessToken, _page);
      
      if (response.isSuccess) {
        final newFollowers = response.data ?? [];
        
        setState(() {
          _followers.addAll(newFollowers);
          _isLoadingMore = false;
          _hasMorePages = newFollowers.isNotEmpty;
          _page++;
        });
      } else {
        setState(() {
          _errorMessage = 'Daha fazla takipçi yüklenemedi: ${response.message}';
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

  Future<void> _removeFollower(int userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await _followService.removeFollower(accessToken, userId);

      if (response.isSuccess) {
        setState(() {
          _followers.removeWhere((follower) => follower.id == userId);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Takipçi kaldırıldı'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Takipçi kaldırılamadı: ${response.message}'),
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

  Future<void> _searchFollowers(String query) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await _followService.searchFollowers(accessToken, query, 1);
      
      if (response.isSuccess) {
        setState(() {
          _followers = response.data ?? [];
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

  void _refreshFollowers() {
    setState(() {
      _page = 1;
      _followers = [];
    });
    _fetchFollowers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Takipçiler', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.search, color: Colors.white),
            onPressed: () {
              showSearch(
                context: context,
                delegate: _FollowersSearchDelegate(
                  onSearch: _searchFollowers,
                  onClear: _refreshFollowers,
                ),
              );
            },
            tooltip: 'Ara',
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _refreshFollowers,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _errorMessage != null
              ? _buildErrorWidget()
              : _followers.isEmpty
                  ? _buildEmptyWidget()
                  : _buildFollowersList(),
    );
  }

  Widget _buildFollowersList() {
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(8),
      itemCount: _followers.length + (_hasMorePages ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == _followers.length) {
          return _buildLoadingMoreIndicator();
        }
        
        final follower = _followers[index];
        return _buildFollowerItem(follower);
      },
    );
  }

  Widget _buildFollowerItem(FollowedUserDTO follower) {
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
            arguments: {'userId': follower.id},
          ),
          child: CircleAvatar(
            radius: 24,
            backgroundColor: Colors.grey[800],
            backgroundImage: follower.profilePhotoUrl != null && follower.profilePhotoUrl!.isNotEmpty
                ? CachedNetworkImageProvider(follower.profilePhotoUrl!)
                : null,
            child: follower.profilePhotoUrl == null || follower.profilePhotoUrl!.isEmpty
                ? const Icon(Icons.person, color: Colors.white60)
                : null,
          ),
        ),
        title: Text(
          '${follower.username}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '@${follower.username}',
              style: TextStyle(color: Colors.grey[400]),
            ),
            if (follower.bio != null && follower.bio!.isNotEmpty)
              Text(
                follower.bio!,
                style: TextStyle(color: Colors.grey[500]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
          ],
        ),
        trailing: _buildActionButton(follower),
        onTap: () => Navigator.pushNamed(
          context,
          '/user-profile',
          arguments: {'userId': follower.id},
        ),
      ),
    );
  }

  Widget _buildActionButton(FollowedUserDTO follower) {
    if (follower.isFollowing ?? false) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          OutlinedButton(
            onPressed: () {},
            style: OutlinedButton.styleFrom(
              side: BorderSide(color: Colors.grey[700]!),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              foregroundColor: Colors.white,
            ),
            child: const Text('Takip Ediliyor'),
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            color: Colors.grey[850],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            onSelected: (value) {
              if (value == 'remove') {
                _removeFollower(follower.id);
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem<String>(
                value: 'remove',
                child: Row(
                  children: [
                    Icon(Icons.person_remove, color: Colors.red, size: 20),
                    SizedBox(width: 8),
                    Text('Takipçiyi Kaldır', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      );
    } else {
      return OutlinedButton(
        onPressed: () {
          // Takip et işlemi - Gerekirse burada implement edilebilir
        },
        style: OutlinedButton.styleFrom(
          backgroundColor: Colors.blue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          foregroundColor: Colors.white,
        ),
        child: const Text('Takip Et'),
      );
    }
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Takipçiler yükleniyor...',
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
              _errorMessage ?? 'Takipçiler yüklenirken bir hata oluştu.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshFollowers,
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
            Icons.person_outline,
            color: Colors.white54,
            size: 80,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz takipçin yok',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Paylaşım yaparak ve profilini tamamlayarak\ndaha fazla takipçi kazanabilirsin.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// Arama işlemleri için delegate sınıfı
class _FollowersSearchDelegate extends SearchDelegate<String> {
  final Function(String) onSearch;
  final VoidCallback onClear;

  _FollowersSearchDelegate({required this.onSearch, required this.onClear});

  @override
  String get searchFieldLabel => 'Takipçilerde ara...';

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