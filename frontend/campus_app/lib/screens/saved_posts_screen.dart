import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/widgets/post_item.dart';

class SavedPostsScreen extends StatefulWidget {
  const SavedPostsScreen({Key? key}) : super(key: key);

  @override
  _SavedPostsScreenState createState() => _SavedPostsScreenState();
}

class _SavedPostsScreenState extends State<SavedPostsScreen> {
  List<Map<String, dynamic>> _savedPosts = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMorePosts = true;
  bool _isLoadingMore = false;
  final int _postsPerPage = 10;
  final ScrollController _scrollController = ScrollController();

  // Koleksiyonlar (yeni özellik)
  final List<String> _collections = ['Tümü', 'Kampüs', 'Dersler', 'Etkinlikler', 'Arkadaşlar'];
  String _selectedCollection = 'Tümü';

  @override
  void initState() {
    super.initState();
    _fetchSavedPosts();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200 &&
        !_isLoadingMore &&
        _hasMorePosts) {
      _loadMorePosts();
    }
  }

  Future<void> _fetchSavedPosts() async {
    if (_isLoading && _currentPage > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      // Koleksiyon filtresi API'ye eklenebilir
      String collectionParam = '';
      if (_selectedCollection != 'Tümü') {
        collectionParam = '&collection=${Uri.encodeComponent(_selectedCollection)}';
      }

      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/api/post/saved-posts?page=$_currentPage&size=$_postsPerPage$collectionParam'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> posts = data['data'] ?? [];
        
        setState(() {
          if (_currentPage == 0) {
            _savedPosts = List<Map<String, dynamic>>.from(posts);
          } else {
            _savedPosts.addAll(List<Map<String, dynamic>>.from(posts));
          }
          
          _hasMorePosts = posts.length >= _postsPerPage;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Kaydedilen gönderiler yüklenirken bir hata oluştu: ${response.statusCode}';
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
    await _fetchSavedPosts();
    
    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _refreshPosts() async {
    _currentPage = 0;
    _hasMorePosts = true;
    await _fetchSavedPosts();
  }

  void _onCollectionChanged(String? newCollection) {
    if (newCollection != null && newCollection != _selectedCollection) {
      setState(() {
        _selectedCollection = newCollection;
        _currentPage = 0;
        _hasMorePosts = true;
      });
      _refreshPosts();
    }
  }

  void _showCreateCollectionDialog() {
    final TextEditingController _collectionNameController = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Yeni Koleksiyon Oluştur',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _collectionNameController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Koleksiyon adı',
            hintStyle: TextStyle(color: Colors.white60),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.indigoAccent),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
            onPressed: () {
              final collectionName = _collectionNameController.text.trim();
              if (collectionName.isNotEmpty) {
                setState(() {
                  _collections.add(collectionName);
                  _selectedCollection = collectionName;
                  _currentPage = 0;
                  _hasMorePosts = true;
                });
                _refreshPosts();
              }
              Navigator.pop(context);
            },
            child: const Text(
              'Oluştur',
              style: TextStyle(color: Colors.indigoAccent),
            ),
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
        title: const Text('Kaydedilen Gönderiler', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_to_photos, color: Colors.white),
            onPressed: _showCreateCollectionDialog,
            tooltip: 'Yeni Koleksiyon Oluştur',
          ),
        ],
      ),
      body: Column(
        children: [
          // Koleksiyon filtreleri
          _buildCollectionFilters(),
          
          // Gönderi listesi veya yükleniyor/hata durumları
          Expanded(
            child: _isLoading && _currentPage == 0
                ? const Center(child: CircularProgressIndicator(color: Colors.white))
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : _savedPosts.isEmpty
                        ? _buildEmptyState()
                        : _buildPostsList(),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionFilters() {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _collections.length + 1, // +1 for the "create new" button at the end
        itemBuilder: (context, index) {
          // Son eleman "yeni koleksiyon oluştur" butonu
          if (index == _collections.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ActionChip(
                backgroundColor: Colors.grey[800],
                avatar: const Icon(Icons.add, color: Colors.white70, size: 18),
                label: const Text(
                  'Yeni',
                  style: TextStyle(color: Colors.white70),
                ),
                onPressed: _showCreateCollectionDialog,
              ),
            );
          }
          
          final collection = _collections[index];
          final isSelected = collection == _selectedCollection;
          
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: FilterChip(
              selected: isSelected,
              selectedColor: Colors.indigoAccent,
              backgroundColor: Colors.grey[800],
              checkmarkColor: Colors.white,
              label: Text(
                collection,
                style: TextStyle(
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
              onSelected: (_) => _onCollectionChanged(collection),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              color: Colors.redAccent,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Bilinmeyen bir hata oluştu',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshPosts,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
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
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.bookmark_border,
              color: Colors.white54,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz kaydedilen gönderi yok',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCollection == 'Tümü'
                  ? 'Kaydettiğiniz gönderiler burada listelenecek'
                  : '"$_selectedCollection" koleksiyonunda henüz gönderi yok',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.white70,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                Navigator.pushNamed(context, '/home');
              },
              icon: const Icon(Icons.explore),
              label: const Text('Keşfet'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList() {
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: Colors.indigoAccent,
      backgroundColor: Colors.grey[900],
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _savedPosts.length + (_hasMorePosts ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _savedPosts.length) {
            return _buildLoadingIndicator();
          }
          return Dismissible(
            key: ValueKey(_savedPosts[index]['postId']),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: Colors.red,
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text(
                    'Gönderiyi Kaldır',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Bu gönderiyi kaydedilenlerden kaldırmak istediğinizden emin misiniz?',
                    style: TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text(
                        'İptal',
                        style: TextStyle(color: Colors.white60),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        'Kaldır',
                        style: TextStyle(color: Colors.redAccent),
                      ),
                    ),
                  ],
                ),
              );
            },
            onDismissed: (direction) async {
              final postId = _savedPosts[index]['postId'];
              final deletedPost = _savedPosts[index];
              final deletedIndex = index;
              
              setState(() {
                _savedPosts.removeAt(index);
              });
              
              try {
                final prefs = await SharedPreferences.getInstance();
                final accessToken = prefs.getString('accessToken') ?? '';

                final response = await http.post(
                  Uri.parse('http://localhost:8080/v1/api/post/record/$postId'),
                  headers: {
                    'Authorization': 'Bearer $accessToken',
                  },
                );

                if (response.statusCode != 200) {
                  // Eğer API çağrısı başarısız olursa, postu geri ekle
                  setState(() {
                    _savedPosts.insert(deletedIndex, deletedPost);
                  });
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gönderi kaldırılamadı'),
                      backgroundColor: Colors.redAccent,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Gönderi kaydedilenlerden kaldırıldı'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                // Hata durumunda postu geri ekle
                setState(() {
                  _savedPosts.insert(deletedIndex, deletedPost);
                });
                
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Bağlantı hatası: $e'),
                    backgroundColor: Colors.redAccent,
                  ),
                );
              }
            },
            child: PostItem(post: _savedPosts[index]),
          );
        },
      ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: const CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(Colors.indigoAccent),
      ),
    );
  }
} 