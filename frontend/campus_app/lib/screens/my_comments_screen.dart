import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timeago/timeago.dart' as timeago;

class MyCommentsScreen extends StatefulWidget {
  const MyCommentsScreen({Key? key}) : super(key: key);

  @override
  _MyCommentsScreenState createState() => _MyCommentsScreenState();
}

class _MyCommentsScreenState extends State<MyCommentsScreen> {
  List<CommentItem> _comments = [];
  bool _isLoading = true;
  String? _errorMessage;
  int _currentPage = 0;
  bool _hasMoreComments = true;
  bool _isLoadingMore = false;
  final int _commentsPerPage = 20;
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _fetchComments();
    _scrollController.addListener(_onScroll);

    // Türkçe dil desteği ekle
    timeago.setLocaleMessages('tr', timeago.TrMessages());
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
        _hasMoreComments) {
      _loadMoreComments();
    }
  }

  Future<void> _fetchComments() async {
    if (_isLoading && _currentPage > 0) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/api/student/comments?page=$_currentPage&size=$_commentsPerPage'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> commentsData = data['data'] ?? [];
        
        // JSON verilerini CommentItem listesine dönüştür
        final comments = commentsData.map((comment) => CommentItem.fromJson(comment)).toList();
        
        setState(() {
          if (_currentPage == 0) {
            _comments = comments;
          } else {
            _comments.addAll(comments);
          }
          
          _hasMoreComments = comments.length >= _commentsPerPage;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Yorumlar yüklenirken bir hata oluştu: ${response.statusCode}';
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

  Future<void> _loadMoreComments() async {
    if (_isLoadingMore || !_hasMoreComments) return;
    
    setState(() {
      _isLoadingMore = true;
    });
    
    _currentPage++;
    await _fetchComments();
    
    setState(() {
      _isLoadingMore = false;
    });
  }

  Future<void> _refreshComments() async {
    _currentPage = 0;
    _hasMoreComments = true;
    await _fetchComments();
  }

  Future<void> _deleteComment(CommentItem comment, int index) async {
    // Yorumu listeden kaldır
    setState(() {
      _comments.removeAt(index);
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.delete(
        Uri.parse('http://localhost:8080/v1/api/comment/${comment.id}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorum başarıyla silindi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // API çağrısı başarısız olursa, yorumu geri ekle
        setState(() {
          _comments.insert(index, comment);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorum silinemedi'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      // Hata oluşursa, yorumu geri ekle
      setState(() {
        _comments.insert(index, comment);
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bağlantı hatası: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showCommentOptions(CommentItem comment, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white38,
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.edit, color: Colors.white),
              title: const Text('Yorumu Düzenle', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                _editComment(comment, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.redAccent),
              title: const Text('Yorumu Sil', style: TextStyle(color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context);
                _confirmDeleteComment(comment, index);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility, color: Colors.white),
              title: const Text('Gönderiyi Görüntüle', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                // Gönderiyi görüntüleme sayfasına yönlendir
                Navigator.pushNamed(
                  context,
                  '/post/${comment.postId}',
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeleteComment(CommentItem comment, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Yorumu Sil',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Bu yorumu silmek istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.white70),
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
              Navigator.pop(context);
              _deleteComment(comment, index);
            },
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.redAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _editComment(CommentItem comment, int index) {
    final TextEditingController _commentController = TextEditingController(text: comment.content);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Yorumu Düzenle',
          style: TextStyle(color: Colors.white),
        ),
        content: TextField(
          controller: _commentController,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(
            hintText: 'Yorumunuzu yazın',
            hintStyle: TextStyle(color: Colors.white60),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.white30),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.indigoAccent),
            ),
          ),
          maxLines: 3,
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
              Navigator.pop(context);
              _updateComment(comment, index, _commentController.text);
            },
            child: const Text(
              'Kaydet',
              style: TextStyle(color: Colors.indigoAccent),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _updateComment(CommentItem comment, int index, String newContent) async {
    if (newContent.trim().isEmpty || newContent.trim() == comment.content) {
      return;
    }

    // Önce mevcut yorumu yedekle
    final originalComment = comment;
    
    // Yorumu geçici olarak güncelle
    setState(() {
      _comments[index] = CommentItem(
        id: comment.id,
        postId: comment.postId,
        content: newContent,
        createdAt: comment.createdAt,
        updatedAt: DateTime.now(),
        postTitle: comment.postTitle,
        postThumbnail: comment.postThumbnail,
      );
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.put(
        Uri.parse('http://localhost:8080/v1/api/comment/${comment.id}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'content': newContent,
        }),
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorum başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        // API çağrısı başarısız olursa, yorumu geri al
        setState(() {
          _comments[index] = originalComment;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Yorum güncellenemedi'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      // Hata durumunda yorumu geri al
      setState(() {
        _comments[index] = originalComment;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bağlantı hatası: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Yorumlarım', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading && _currentPage == 0
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : _errorMessage != null
              ? _buildErrorWidget()
              : _comments.isEmpty
                  ? _buildEmptyState()
                  : _buildCommentsList(),
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
              onPressed: _refreshComments,
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
              Icons.comment_outlined,
              color: Colors.white54,
              size: 80,
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz yorum yapmadınız',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              'Gönderilere yaptığınız yorumlar burada görünecek',
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

  Widget _buildCommentsList() {
    return RefreshIndicator(
      onRefresh: _refreshComments,
      color: Colors.indigoAccent,
      backgroundColor: Colors.grey[900],
      child: ListView.builder(
        controller: _scrollController,
        itemCount: _comments.length + (_hasMoreComments ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _comments.length) {
            return _buildLoadingIndicator();
          }
          
          final comment = _comments[index];
          return _buildCommentItem(comment, index);
        },
      ),
    );
  }

  Widget _buildCommentItem(CommentItem comment, int index) {
    // Yorumun kaç zaman önce yapıldığını hesapla
    final timeAgo = timeago.format(comment.createdAt, locale: 'tr');
    
    return Dismissible(
      key: ValueKey(comment.id),
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
              'Yorumu Sil',
              style: TextStyle(color: Colors.white),
            ),
            content: const Text(
              'Bu yorumu silmek istediğinizden emin misiniz?',
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
                  'Sil',
                  style: TextStyle(color: Colors.redAccent),
                ),
              ),
            ],
          ),
        );
      },
      onDismissed: (direction) {
        _deleteComment(comment, index);
      },
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: Colors.grey[900],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            // Gönderiyi görüntüleme sayfasına yönlendir
            Navigator.pushNamed(
              context,
              '/post/${comment.postId}',
            );
          },
          onLongPress: () {
            _showCommentOptions(comment, index);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Gönderinin bilgileri
                Row(
                  children: [
                    // Gönderi thumbnail
                    if (comment.postThumbnail != null && comment.postThumbnail!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: CachedNetworkImage(
                          imageUrl: comment.postThumbnail!,
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[800],
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white38),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[800],
                            child: const Icon(Icons.image_not_supported, color: Colors.white38),
                          ),
                        ),
                      )
                    else
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: Colors.grey[800],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.photo, color: Colors.white38),
                      ),
                    const SizedBox(width: 12),
                    
                    // Gönderi başlığı ve tarih
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            comment.postTitle ?? 'Gönderi',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // İşlem menüsü
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white70),
                      onPressed: () => _showCommentOptions(comment, index),
                    ),
                  ],
                ),
                
                // Yorum içeriği
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    comment.content,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                
                // Düzenleme bilgisi
                if (comment.updatedAt != null && comment.updatedAt!.isAfter(comment.createdAt.add(const Duration(minutes: 1))))
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      'Düzenlendi: ${timeago.format(comment.updatedAt!, locale: 'tr')}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.4),
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
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

class CommentItem {
  final String id;
  final String postId;
  final String content;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String? postTitle;
  final String? postThumbnail;

  CommentItem({
    required this.id,
    required this.postId,
    required this.content,
    required this.createdAt,
    this.updatedAt,
    this.postTitle,
    this.postThumbnail,
  });

  factory CommentItem.fromJson(Map<String, dynamic> json) {
    return CommentItem(
      id: json['id'] ?? '',
      postId: json['postId'] ?? '',
      content: json['content'] ?? '',
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      postTitle: json['postTitle'],
      postThumbnail: json['postThumbnail'],
    );
  }
} 