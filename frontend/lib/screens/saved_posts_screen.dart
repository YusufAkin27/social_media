import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/widgets/post_item.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:social_media/theme/app_theme.dart';

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
  final List<String> _collections = [
    'Tümü',
    'Kampüs',
    'Dersler',
    'Etkinlikler',
    'Arkadaşlar'
  ];
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
    if (_scrollController.position.pixels >=
            _scrollController.position.maxScrollExtent - 200 &&
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
        collectionParam =
            '&collection=${Uri.encodeComponent(_selectedCollection)}';
      }

      final response = await http.get(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/post/saved-posts?page=$_currentPage&size=$_postsPerPage$collectionParam'),
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
          _errorMessage =
              'Kaydedilen gönderiler yüklenirken bir hata oluştu: ${response.statusCode}';
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
    final TextEditingController _collectionNameController =
        TextEditingController();
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final backgroundColor =
        isDarkMode ? Theme.of(context).cardColor : Theme.of(context).cardColor;
    final textColor = isDarkMode
        ? Colors.white
        : Theme.of(context).textTheme.bodyLarge?.color;
    final textSecondaryColor = isDarkMode
        ? Colors.white60
        : Theme.of(context).textTheme.bodySmall?.color;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: backgroundColor,
        title: Text(
          'Yeni Koleksiyon Oluştur',
          style: TextStyle(color: textColor),
        ),
        content: TextField(
          controller: _collectionNameController,
          style: TextStyle(color: textColor),
          decoration: InputDecoration(
            hintText: 'Koleksiyon adı',
            hintStyle: TextStyle(color: textSecondaryColor),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                  color: textSecondaryColor?.withOpacity(0.3) ?? Colors.grey),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: accentColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(color: textSecondaryColor),
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
            child: Text(
              'Oluştur',
              style: TextStyle(color: accentColor),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Tema değişimine göre renkleri ayarla
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final textSecondaryColor = Theme.of(context).textTheme.bodySmall?.color;

    // Tema değişimine göre aksan ve vurgu renkleri
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final errorColor = isDarkMode ? AppColors.error : AppColors.lightError;
    final successColor =
        isDarkMode ? AppColors.success : AppColors.lightSuccess;
    final chipColor = isDarkMode ? Colors.grey[800] : Colors.grey[300];

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title:
            Text('Kaydedilen Gönderiler', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          IconButton(
            icon: Icon(Icons.add_to_photos, color: textColor),
            onPressed: _showCreateCollectionDialog,
            tooltip: 'Yeni Koleksiyon Oluştur',
          ),
        ],
      ),
      body: Column(
        children: [
          // Koleksiyon filtreleri
          _buildCollectionFilters(
              accentColor, chipColor, textColor, textSecondaryColor),

          // Gönderi listesi veya yükleniyor/hata durumları
          Expanded(
            child: _isLoading && _currentPage == 0
                ? Center(child: CircularProgressIndicator(color: accentColor))
                : _errorMessage != null
                    ? _buildErrorWidget(
                        accentColor, errorColor, textColor, textSecondaryColor)
                    : _savedPosts.isEmpty
                        ? _buildEmptyState(
                            accentColor, textColor, textSecondaryColor)
                        : _buildPostsList(
                            accentColor,
                            backgroundColor,
                            cardColor,
                            errorColor,
                            successColor,
                            textColor,
                            textSecondaryColor),
          ),
        ],
      ),
    );
  }

  Widget _buildCollectionFilters(Color accentColor, Color? chipColor,
      Color? textColor, Color? textSecondaryColor) {
    return Container(
      height: 50,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: _collections.length +
            1, // +1 for the "create new" button at the end
        itemBuilder: (context, index) {
          // Son eleman "yeni koleksiyon oluştur" butonu
          if (index == _collections.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: ActionChip(
                backgroundColor: chipColor,
                avatar: Icon(Icons.add, color: textSecondaryColor, size: 18),
                label: Text(
                  'Yeni',
                  style: TextStyle(color: textSecondaryColor),
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
              selectedColor: accentColor,
              backgroundColor: chipColor,
              checkmarkColor: Colors.white,
              label: Text(
                collection,
                style: TextStyle(
                  color: isSelected ? Colors.white : textSecondaryColor,
                ),
              ),
              onSelected: (_) => _onCollectionChanged(collection),
            ),
          );
        },
      ),
    );
  }

  Widget _buildErrorWidget(Color accentColor, Color errorColor,
      Color? textColor, Color? textSecondaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: errorColor,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Bilinmeyen bir hata oluştu',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondaryColor,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _refreshPosts,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
      Color accentColor, Color? textColor, Color? textSecondaryColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.bookmark_border,
              color: textSecondaryColor,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz kaydedilen gönderi yok',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _selectedCollection == 'Tümü'
                  ? 'Kaydettiğiniz gönderiler burada listelenecek'
                  : '"$_selectedCollection" koleksiyonunda henüz gönderi yok',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textSecondaryColor,
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
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPostsList(
      Color accentColor,
      Color backgroundColor,
      Color cardColor,
      Color errorColor,
      Color successColor,
      Color? textColor,
      Color? textSecondaryColor) {
    return RefreshIndicator(
      onRefresh: _refreshPosts,
      color: accentColor,
      backgroundColor: cardColor,
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _savedPosts.length + (_hasMorePosts ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _savedPosts.length) {
            return _buildLoadingIndicator(accentColor);
          }
          return Dismissible(
            key: ValueKey(_savedPosts[index]['postId']),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20),
              color: errorColor,
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  backgroundColor: cardColor,
                  title: Text(
                    'Gönderiyi Kaldır',
                    style: TextStyle(color: textColor),
                  ),
                  content: Text(
                    'Bu gönderiyi kaydedilenlerden kaldırmak istediğinizden emin misiniz?',
                    style: TextStyle(color: textSecondaryColor),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text(
                        'İptal',
                        style: TextStyle(color: textSecondaryColor),
                      ),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text(
                        'Kaldır',
                        style: TextStyle(color: errorColor),
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
                  Uri.parse(
                      'http://192.168.89.61:8080/v1/api/post/record/$postId'),
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
                    SnackBar(
                      content: Text('Gönderi kaldırılamadı'),
                      backgroundColor: errorColor,
                    ),
                  );
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Gönderi kaydedilenlerden kaldırıldı'),
                      backgroundColor: successColor,
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
                    backgroundColor: errorColor,
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

  Widget _buildLoadingIndicator(Color accentColor) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      alignment: Alignment.center,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(accentColor),
      ),
    );
  }
}
