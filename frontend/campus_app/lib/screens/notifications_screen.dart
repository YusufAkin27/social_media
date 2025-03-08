import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'package:line_icons/line_icons.dart';
import '../widgets/message_display.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with TickerProviderStateMixin {
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  bool _hasError = false;
  String? _errorMessage;
  late TabController _tabController;
  bool _isDeleting = false;
  final List<String> _selectedNotifications = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadNotifications();
    
    // Bildirim sayısını periyodik olarak kontrol et
    _startPeriodicCheck();
  }

  void _startPeriodicCheck() {
    Future.delayed(const Duration(minutes: 1), () {
      if (mounted) {
        _checkNewNotifications();
        _startPeriodicCheck();
      }
    });
  }

  Future<void> _checkNewNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/api/notifications/unread-count'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        int unreadCount = data['count'] ?? 0;
        
        if (unreadCount > 0) {
          _loadNotifications();
        }
      }
    } catch (e) {
      // Sessiz hata - kullanıcıyı rahatsız etmemek için gösterilmez
      debugPrint('Bildirim kontrolü hatası: $e');
    }
  }

  Future<void> _loadNotifications() async {
    if (_isLoading) return;
    
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/api/notifications'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
          _isLoading = false;
        });
      } else {
        _showError('Bildirimler alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Bağlantı hatası: $e');
    }
  }

  void _showError(String message) {
    setState(() {
      _hasError = true;
      _errorMessage = message;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _markAsRead(String notificationId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await http.post(
        Uri.parse('http://localhost:8080/v1/api/notifications/$notificationId/mark-read'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          final index = _notifications.indexWhere((n) => n['id'] == notificationId);
          if (index != -1) {
            _notifications[index]['isRead'] = true;
          }
        });
      }
    } catch (e) {
      debugPrint('Bildirim okundu işaretleme hatası: $e');
    }
  }

  Future<void> _deleteNotifications(List<String> notificationIds) async {
    setState(() => _isDeleting = true);
    
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await http.delete(
        Uri.parse('http://localhost:8080/v1/api/notifications'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: json.encode({'notificationIds': notificationIds}),
      );

      if (response.statusCode == 200) {
        setState(() {
          _notifications.removeWhere((n) => notificationIds.contains(n['id']));
          _selectedNotifications.clear();
          _isSelectionMode = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bildirimler silindi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Bildirimler silinemedi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      setState(() => _isDeleting = false);
    }
  }

  void _navigateToContent(Map<String, dynamic> notification) {
    String type = notification['type'] ?? 'unknown';
    
    switch (type) {
      case 'like_post':
      case 'comment':
        Navigator.pushNamed(
          context, 
          '/post/${notification['postId']}',
          arguments: {
            'commentId': type == 'comment' ? notification['commentId'] : null,
          },
        );
        break;
      case 'follow':
        Navigator.pushNamed(
          context,
          '/profile/${notification['actorId']}',
        );
        break;
      case 'mention':
        Navigator.pushNamed(
          context,
          '/post/${notification['postId']}',
          arguments: {'mentionId': notification['mentionId']},
        );
        break;
      case 'tag':
        Navigator.pushNamed(
          context,
          '/post/${notification['postId']}',
          arguments: {'tagId': notification['tagId']},
        );
        break;
    }
    
    _markAsRead(notification['id']);
  }

  void _navigateToUserProfile(String userId) {
    Navigator.pushNamed(context, '/profile/$userId');
  }

  String _getNotificationText(Map<String, dynamic> notification) {
    String type = notification['type'] ?? 'unknown';
    String actorName = notification['actorName'] ?? 'Bir kullanıcı';
    
    switch (type) {
      case 'like_post':
        return '$actorName gönderinizi beğendi';
      case 'comment':
        return '$actorName: ${notification['commentText'] ?? 'gönderinize yorum yaptı'}';
      case 'follow':
        return '$actorName sizi takip etmeye başladı';
      case 'mention':
        return '$actorName sizi bir gönderide etiketledi';
      case 'tag':
        return '$actorName bir fotoğrafta sizi etiketledi';
      default:
        return 'Yeni bir bildiriminiz var';
    }
  }

  Widget _getNotificationIcon(Map<String, dynamic> notification) {
    String type = notification['type'] ?? 'unknown';
    
    switch (type) {
      case 'like_post':
        return const Icon(CupertinoIcons.heart_fill, color: Colors.red, size: 20);
      case 'comment':
        return const Icon(CupertinoIcons.chat_bubble_fill, color: Colors.blue, size: 20);
      case 'follow':
        return const Icon(CupertinoIcons.person_crop_circle_fill_badge_plus, color: Colors.green, size: 20);
      case 'mention':
        return const Icon(CupertinoIcons.at, color: Colors.orange, size: 20);
      case 'tag':
        return const Icon(CupertinoIcons.tag_fill, color: Colors.purple, size: 20);
      default:
        return const Icon(CupertinoIcons.bell_fill, color: Colors.white, size: 20);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Text(
          _isSelectionMode 
              ? '${_selectedNotifications.length} seçildi'
              : 'Bildirimler',
          style: const TextStyle(color: Colors.white),
        ),
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: () {
                  setState(() {
                    _isSelectionMode = false;
                    _selectedNotifications.clear();
                  });
                },
              )
            : null,
        actions: [
          if (_isSelectionMode)
            IconButton(
              icon: const Icon(Icons.delete_outline),
              onPressed: _selectedNotifications.isEmpty
                  ? null
                  : () => _deleteNotifications(_selectedNotifications),
            )
          else ...[
            IconButton(
              icon: const Icon(Icons.checklist_rtl_outlined),
              onPressed: () {
                setState(() => _isSelectionMode = true);
              },
            ),
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loadNotifications,
            ),
          ],
        ],
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          tabs: const [
            Tab(text: 'Tümü'),
            Tab(text: 'Okunmamış'),
          ],
        ),
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _hasError
              ? _buildErrorWidget()
              : _notifications.isEmpty
                  ? _buildEmptyState()
                  : _buildNotificationsList(),
    );
  }

  Widget _buildLoadingIndicator() {
    return const Center(
      child: CircularProgressIndicator(color: Colors.white),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 60),
            const SizedBox(height: 16),
            Text(
              'Hata',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: Colors.white),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Bildirimler yüklenirken bir hata oluştu.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadNotifications,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
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
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            CupertinoIcons.bell_slash,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz bildiriminiz yok',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Bildirimleriniz burada görünecek',
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationsList() {
    final filteredNotifications = _tabController.index == 0
        ? _notifications
        : _notifications.where((n) => !(n['isRead'] ?? false)).toList();

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: Colors.white,
      backgroundColor: Colors.blue,
      child: ListView.builder(
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          final bool isRead = notification['isRead'] ?? false;
          final DateTime createdAt = DateTime.parse(notification['createdAt'] ?? DateTime.now().toIso8601String());
          final String notificationId = notification['id'] ?? '';
          final bool isSelected = _selectedNotifications.contains(notificationId);
          
          return Dismissible(
            key: Key(notificationId),
            direction: DismissDirection.endToStart,
            confirmDismiss: (direction) async {
              return await showDialog(
                context: context,
                builder: (BuildContext context) {
                  return AlertDialog(
                    backgroundColor: Colors.grey[900],
                    title: const Text(
                      'Bildirimi Sil',
                      style: TextStyle(color: Colors.white),
                    ),
                    content: const Text(
                      'Bu bildirimi silmek istediğinizden emin misiniz?',
                      style: TextStyle(color: Colors.white70),
                    ),
                    actions: <Widget>[
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(false),
                        child: const Text('İptal'),
                      ),
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(true),
                        child: const Text(
                          'Sil',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ],
                  );
                },
              );
            },
            onDismissed: (direction) {
              _deleteNotifications([notificationId]);
            },
            background: Container(
              color: Colors.red,
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 20.0),
              child: const Icon(
                Icons.delete,
                color: Colors.white,
              ),
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isSelected
                    ? Colors.blue.withOpacity(0.2)
                    : (isRead ? Colors.black : Colors.grey.withOpacity(0.1)),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.grey.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: ListTile(
                leading: Stack(
                  children: [
                    if (_isSelectionMode)
                      Checkbox(
                        value: isSelected,
                        onChanged: (bool? value) {
                          setState(() {
                            if (value == true) {
                              _selectedNotifications.add(notificationId);
                            } else {
                              _selectedNotifications.remove(notificationId);
                            }
                          });
                        },
                        fillColor: MaterialStateProperty.resolveWith<Color>(
                          (Set<MaterialState> states) {
                            if (states.contains(MaterialState.selected)) {
                              return Colors.blue;
                            }
                            return Colors.grey;
                          },
                        ),
                      )
                    else
                      GestureDetector(
                        onTap: () => _navigateToUserProfile(notification['actorId']),
                        child: CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          backgroundImage: notification['actorAvatar'] != null
                              ? NetworkImage(notification['actorAvatar'])
                              : null,
                          child: notification['actorAvatar'] == null
                              ? _getNotificationIcon(notification)
                              : null,
                        ),
                      ),
                  ],
                ),
                title: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: notification['actorName'] ?? 'Bir kullanıcı',
                        style: const TextStyle(
                          color: Colors.blue,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      TextSpan(
                        text: ' ${_getNotificationText(notification).split(':').last}',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      timeago.format(createdAt, locale: 'tr'),
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                    if (notification['type'] == 'comment' && notification['commentText'] != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          notification['commentText'],
                          style: TextStyle(
                            color: Colors.grey[400],
                            fontSize: 13,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                onTap: _isSelectionMode
                    ? () {
                        setState(() {
                          if (isSelected) {
                            _selectedNotifications.remove(notificationId);
                          } else {
                            _selectedNotifications.add(notificationId);
                          }
                        });
                      }
                    : () => _navigateToContent(notification),
                onLongPress: () {
                  if (!_isSelectionMode) {
                    setState(() {
                      _isSelectionMode = true;
                      _selectedNotifications.add(notificationId);
                    });
                  }
                },
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
} 