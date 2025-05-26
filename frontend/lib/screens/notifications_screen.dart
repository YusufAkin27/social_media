import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'package:line_icons/line_icons.dart';
import 'package:flutter_svg/flutter_svg.dart';
// import '../widgets/message_display.dart';
import '../widgets/error_toast.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:social_media/theme/app_theme.dart';

// Notification type enum for better type safety
enum NotificationType {
  likePost,
  comment,
  follow,
  mention,
  tag,
  followRequest,
  acceptedFollow,
  newLogin,
  newDevice,
  postTag,
  message
}

// Notification model class
class NotificationModel {
  final String id;
  final NotificationType type;
  final String actorId;
  final String actorName;
  final String? actorAvatar;
  final String? postId;
  final String? commentId;
  final String? commentText;
  final String? mentionId;
  final String? tagId;
  final String? deviceInfo;
  final String? location;
  final DateTime createdAt;
  bool isRead;
  bool isActionTaken;

  NotificationModel({
    required this.id,
    required this.type,
    required this.actorId,
    required this.actorName,
    this.actorAvatar,
    this.postId,
    this.commentId,
    this.commentText,
    this.mentionId,
    this.tagId,
    this.deviceInfo,
    this.location,
    required this.createdAt,
    this.isRead = false,
    this.isActionTaken = false,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      type: _typeFromString(json['type'] ?? ''),
      actorId: json['actorId'] ?? '',
      actorName: json['actorName'] ?? 'Bir kullanıcı',
      actorAvatar: json['actorAvatar'],
      postId: json['postId'],
      commentId: json['commentId'],
      commentText: json['commentText'],
      mentionId: json['mentionId'],
      tagId: json['tagId'],
      deviceInfo: json['deviceInfo'],
      location: json['location'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      isActionTaken: json['isActionTaken'] ?? false,
    );
  }

  static NotificationType _typeFromString(String type) {
    switch (type) {
      case 'like_post':
        return NotificationType.likePost;
      case 'comment':
        return NotificationType.comment;
      case 'follow':
        return NotificationType.follow;
      case 'mention':
        return NotificationType.mention;
      case 'tag':
        return NotificationType.tag;
      case 'follow_request':
        return NotificationType.followRequest;
      case 'accepted_follow':
        return NotificationType.acceptedFollow;
      case 'new_login':
        return NotificationType.newLogin;
      case 'new_device':
        return NotificationType.newDevice;
      case 'post_tag':
        return NotificationType.postTag;
      case 'message':
        return NotificationType.message;
      default:
        return NotificationType.mention;
    }
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': _stringFromType(type),
      'actorId': actorId,
      'actorName': actorName,
      'actorAvatar': actorAvatar,
      'postId': postId,
      'commentId': commentId,
      'commentText': commentText,
      'mentionId': mentionId,
      'tagId': tagId,
      'deviceInfo': deviceInfo,
      'location': location,
      'createdAt': createdAt.toIso8601String(),
      'isRead': isRead,
      'isActionTaken': isActionTaken,
    };
  }

  static String _stringFromType(NotificationType type) {
    switch (type) {
      case NotificationType.likePost:
        return 'like_post';
      case NotificationType.comment:
        return 'comment';
      case NotificationType.follow:
        return 'follow';
      case NotificationType.mention:
        return 'mention';
      case NotificationType.tag:
        return 'tag';
      case NotificationType.followRequest:
        return 'follow_request';
      case NotificationType.acceptedFollow:
        return 'accepted_follow';
      case NotificationType.newLogin:
        return 'new_login';
      case NotificationType.newDevice:
        return 'new_device';
      case NotificationType.postTag:
        return 'post_tag';
      case NotificationType.message:
        return 'message';
    }
  }
}

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  _NotificationsScreenState createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen>
    with TickerProviderStateMixin {
  bool _isLoading = true;
  List<NotificationModel> _notifications = [];
  bool _hasError = false;
  String? _errorMessage;
  late TabController _tabController;
  bool _isDeleting = false;
  final List<String> _selectedNotifications = [];
  bool _isSelectionMode = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/notifications/unread-count'),
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
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      // Bu kısımda normalde API'den veri alacaksınız, ancak şimdilik örnek verileri yükleyelim
      await Future.delayed(const Duration(
          milliseconds: 1500)); // Simüle edilen yükleme gecikmesi

      setState(() {
        _notifications = _getMockNotifications();
        _isLoading = false;
      });
    } catch (e) {
      _showError('Bağlantı hatası: $e');
    }
  }

  // Örnek bildirim verileri
  List<NotificationModel> _getMockNotifications() {
    return [
      // Takip istekleri
      NotificationModel(
        id: '1',
        type: NotificationType.followRequest,
        actorId: '101',
        actorName: 'Zeynep Yılmaz',
        actorAvatar: 'https://randomuser.me/api/portraits/women/33.jpg',
        createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
        isRead: false,
        isActionTaken: false,
      ),
      NotificationModel(
        id: '11',
        type: NotificationType.followRequest,
        actorId: '111',
        actorName: 'Murat Kaya',
        actorAvatar: 'https://randomuser.me/api/portraits/men/45.jpg',
        createdAt: DateTime.now().subtract(const Duration(hours: 1)),
        isRead: false,
        isActionTaken: false,
      ),
      NotificationModel(
        id: '12',
        type: NotificationType.followRequest,
        actorId: '112',
        actorName: 'Selin Taş',
        actorAvatar: 'https://randomuser.me/api/portraits/women/28.jpg',
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        isRead: false,
        isActionTaken: false,
      ),

      // Beğeni bildirimleri
      NotificationModel(
        id: '2',
        type: NotificationType.likePost,
        actorId: '102',
        actorName: 'Ahmet Kaya',
        actorAvatar: 'https://randomuser.me/api/portraits/men/44.jpg',
        postId: '201',
        createdAt: DateTime.now().subtract(const Duration(hours: 2)),
        isRead: true,
      ),
      NotificationModel(
        id: '13',
        type: NotificationType.likePost,
        actorId: '113',
        actorName: 'Gökhan Tekin',
        actorAvatar: 'https://randomuser.me/api/portraits/men/36.jpg',
        postId: '204',
        createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
        isRead: false,
      ),

      // Yorum bildirimleri
      NotificationModel(
        id: '3',
        type: NotificationType.comment,
        actorId: '103',
        actorName: 'Ayşe Demir',
        actorAvatar: 'https://randomuser.me/api/portraits/women/67.jpg',
        postId: '201',
        commentId: '301',
        commentText: 'Harika bir fotoğraf! Hangi kampüste çekildi bu?',
        createdAt: DateTime.now().subtract(const Duration(hours: 6)),
        isRead: false,
      ),
      NotificationModel(
        id: '14',
        type: NotificationType.comment,
        actorId: '114',
        actorName: 'Berk Yılmaz',
        actorAvatar: 'https://randomuser.me/api/portraits/men/75.jpg',
        postId: '202',
        commentId: '302',
        commentText:
            'Bu konuda bir çalışma grubu kuralım, ben de katılmak isterim!',
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        isRead: false,
      ),

      // Diğer bildirimler
      NotificationModel(
        id: '4',
        type: NotificationType.acceptedFollow,
        actorId: '104',
        actorName: 'Mehmet Öz',
        actorAvatar: 'https://randomuser.me/api/portraits/men/32.jpg',
        createdAt: DateTime.now().subtract(const Duration(hours: 12)),
        isRead: true,
      ),
      NotificationModel(
        id: '5',
        type: NotificationType.mention,
        actorId: '105',
        actorName: 'Deniz Yıldız',
        actorAvatar: 'https://randomuser.me/api/portraits/women/22.jpg',
        postId: '202',
        mentionId: '401',
        createdAt: DateTime.now().subtract(const Duration(days: 1)),
        isRead: false,
      ),
      NotificationModel(
        id: '6',
        type: NotificationType.newDevice,
        actorId: '106',
        actorName: 'Sistem',
        deviceInfo: 'iPhone 14 - İstanbul',
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
        isRead: true,
      ),
      NotificationModel(
        id: '7',
        type: NotificationType.followRequest,
        actorId: '107',
        actorName: 'Cem Yılmaz',
        actorAvatar: 'https://randomuser.me/api/portraits/men/86.jpg',
        createdAt: DateTime.now().subtract(const Duration(days: 2, hours: 12)),
        isRead: true,
        isActionTaken: true,
      ),
      NotificationModel(
        id: '8',
        type: NotificationType.message,
        actorId: '108',
        actorName: 'Pınar Akın',
        actorAvatar: 'https://randomuser.me/api/portraits/women/56.jpg',
        commentText: 'Merhaba, yarınki etkinlik hakkında konuşabilir miyiz?',
        createdAt: DateTime.now().subtract(const Duration(days: 3)),
        isRead: false,
      ),
      NotificationModel(
        id: '9',
        type: NotificationType.postTag,
        actorId: '109',
        actorName: 'Ece Bakırcı',
        actorAvatar: 'https://randomuser.me/api/portraits/women/62.jpg',
        postId: '203',
        createdAt: DateTime.now().subtract(const Duration(days: 4)),
        isRead: true,
      ),
      NotificationModel(
        id: '10',
        type: NotificationType.newLogin,
        actorId: '110',
        actorName: 'Sistem',
        location: 'Ankara, Türkiye',
        deviceInfo: 'Chrome - Windows 10',
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
        isRead: false,
      ),
    ];
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
      // API ile gerçek entegrasyonda burada bir API çağrısı yapılacak

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index].isRead = true;
        }
      });
    } catch (e) {
      debugPrint('Bildirim okundu işaretleme hatası: $e');
    }
  }

  Future<void> _deleteNotifications(List<String> notificationIds) async {
    setState(() => _isDeleting = true);

    try {
      // API entegrasyonunda burada delete işlemi yapılacak
      await Future.delayed(
          const Duration(milliseconds: 800)); // Simüle edilen silme işlemi

      setState(() {
        _notifications.removeWhere((n) => notificationIds.contains(n.id));
        _selectedNotifications.clear();
        _isSelectionMode = false;
        _isDeleting = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Bildirimler silindi'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      setState(() => _isDeleting = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Takip isteğini kabul etme işlemi
  Future<void> _acceptFollowRequest(
      String userId, String notificationId) async {
    try {
      // Gerçek uygulamada API çağrısı yapılır
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simüle edilmiş işlem

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index].isActionTaken = true;
          _notifications[index].isRead = true;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Takip isteği kabul edildi'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem başarısız: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Takip isteğini reddetme işlemi
  Future<void> _rejectFollowRequest(
      String userId, String notificationId) async {
    try {
      // Gerçek uygulamada API çağrısı yapılır
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simüle edilmiş işlem

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index].isActionTaken = true;
          _notifications[index].isRead = true;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Takip isteği reddedildi'),
          backgroundColor: Colors.blueGrey,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem başarısız: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Yeni cihaz girişi onaylama
  Future<void> _confirmDevice(String notificationId) async {
    try {
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simüle edilmiş işlem

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index].isActionTaken = true;
          _notifications[index].isRead = true;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Cihaz girişi onaylandı'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem başarısız: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  // Şüpheli giriş bildirimi
  Future<void> _reportSuspiciousLogin(String notificationId) async {
    try {
      await Future.delayed(
          const Duration(milliseconds: 500)); // Simüle edilmiş işlem

      setState(() {
        final index = _notifications.indexWhere((n) => n.id == notificationId);
        if (index != -1) {
          _notifications[index].isActionTaken = true;
          _notifications[index].isRead = true;
        }
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Şüpheli giriş bildirimi gönderildi'),
          backgroundColor: Colors.amber,
          behavior: SnackBarBehavior.floating,
        ),
      );

      // Bu durumda güvenlik ekranına yönlendirme yapılabilir
      // Navigator.pushNamed(context, '/security');
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('İşlem başarısız: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _navigateToContent(NotificationModel notification) {
    // Bildirim türüne göre ilgili sayfaya yönlendirme
    switch (notification.type) {
      case NotificationType.likePost:
      case NotificationType.comment:
      case NotificationType.postTag:
        if (notification.postId != null) {
          Navigator.pushNamed(
            context,
            '/post/${notification.postId}',
            arguments: {
              'commentId': notification.type == NotificationType.comment
                  ? notification.commentId
                  : null,
            },
          );
        }
        break;

      case NotificationType.follow:
      case NotificationType.acceptedFollow:
        Navigator.pushNamed(
          context,
          '/profile/${notification.actorId}',
        );
        break;

      case NotificationType.mention:
        if (notification.postId != null) {
          Navigator.pushNamed(
            context,
            '/post/${notification.postId}',
            arguments: {'mentionId': notification.mentionId},
          );
        }
        break;

      case NotificationType.tag:
        if (notification.postId != null) {
          Navigator.pushNamed(
            context,
            '/post/${notification.postId}',
            arguments: {'tagId': notification.tagId},
          );
        }
        break;

      case NotificationType.message:
        Navigator.pushNamed(
          context,
          '/messages/${notification.actorId}',
        );
        break;

      case NotificationType.newLogin:
      case NotificationType.newDevice:
        Navigator.pushNamed(
          context,
          '/settings/security',
        );
        break;

      case NotificationType.followRequest:
        // Takip isteği bildirimleri için özel işlem zaten yapılıyor
        break;
    }

    _markAsRead(notification.id);
  }

  void _navigateToUserProfile(String userId) {
    Navigator.pushNamed(context, '/profile/$userId');
  }

  String _getNotificationText(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.likePost:
        return 'gönderinizi beğendi';
      case NotificationType.comment:
        return notification.commentText != null
            ? ': ${notification.commentText}'
            : 'gönderinize yorum yaptı';
      case NotificationType.follow:
        return 'sizi takip etmeye başladı';
      case NotificationType.mention:
        return 'sizi bir gönderide etiketledi';
      case NotificationType.tag:
        return 'bir fotoğrafta sizi etiketledi';
      case NotificationType.followRequest:
        return 'sizi takip etmek istiyor';
      case NotificationType.acceptedFollow:
        return 'takip isteğinizi kabul etti';
      case NotificationType.newLogin:
        return 'Yeni bir cihazdan giriş yapıldı: ${notification.deviceInfo}${notification.location != null ? ' - ${notification.location}' : ''}';
      case NotificationType.newDevice:
        return 'Yeni cihaz algılandı: ${notification.deviceInfo}';
      case NotificationType.postTag:
        return 'sizi bir gönderide etiketledi';
      case NotificationType.message:
        return 'size mesaj gönderdi: ${notification.commentText ?? ''}';
      default:
        return 'Yeni bir bildiriminiz var';
    }
  }

  Widget _getNotificationIcon(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.likePost:
        return Icon(CupertinoIcons.heart_fill, color: Colors.red, size: 22);
      case NotificationType.comment:
        return Icon(CupertinoIcons.chat_bubble_fill,
            color: Colors.blue, size: 22);
      case NotificationType.follow:
        return Icon(CupertinoIcons.person_badge_plus_fill,
            color: Colors.green, size: 22);
      case NotificationType.mention:
        return Icon(CupertinoIcons.at, color: Colors.orange, size: 22);
      case NotificationType.tag:
        return Icon(CupertinoIcons.tag_fill, color: Colors.purple, size: 22);
      case NotificationType.followRequest:
        return Icon(CupertinoIcons.person_add,
            color: Colors.lightBlue, size: 22);
      case NotificationType.acceptedFollow:
        return Icon(CupertinoIcons.check_mark_circled_solid,
            color: Colors.green, size: 22);
      case NotificationType.newLogin:
        return Icon(CupertinoIcons.lock_shield_fill,
            color: Colors.amber, size: 22);
      case NotificationType.newDevice:
        return Icon(CupertinoIcons.device_phone_portrait,
            color: Colors.deepOrange, size: 22);
      case NotificationType.postTag:
        return Icon(CupertinoIcons.photo_fill, color: Colors.teal, size: 22);
      case NotificationType.message:
        return Icon(CupertinoIcons.chat_bubble_text_fill,
            color: Colors.indigo, size: 22);
      default:
        return Icon(CupertinoIcons.bell_fill, color: Colors.white, size: 22);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Tema provider'dan tema bilgilerini al
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Tema bazlı renkler
    final backgroundColor =
        isDarkMode ? AppColors.background : AppColors.lightBackground;
    final cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final surfaceColor =
        isDarkMode ? AppColors.surfaceColor : AppColors.lightSurfaceColor;
    final textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;
    final secondaryTextColor =
        isDarkMode ? AppColors.secondaryText : AppColors.lightSecondaryText;
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final dividerColor = isDarkMode ? AppColors.divider : Colors.grey.shade300;

    // Unread notification counts
    final int unreadCount = _notifications.where((n) => !n.isRead).length;
    final int requestCount = _notifications
        .where(
            (n) => n.type == NotificationType.followRequest && !n.isActionTaken)
        .length;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: _buildAppBar(unreadCount, requestCount, backgroundColor,
          textColor, cardColor, secondaryTextColor, accentColor, dividerColor),
      body: _isLoading
          ? _buildLoadingIndicator(accentColor, cardColor)
          : _hasError
              ? _buildErrorWidget(
                  cardColor, textColor, secondaryTextColor, accentColor)
              : _notifications.isEmpty
                  ? _buildEmptyState(cardColor, textColor, secondaryTextColor,
                      accentColor, dividerColor)
                  : _buildNotificationsList(
                      cardColor,
                      textColor,
                      secondaryTextColor,
                      accentColor,
                      surfaceColor,
                      dividerColor),
    );
  }

  PreferredSizeWidget _buildAppBar(
      int unreadCount,
      int requestCount,
      Color backgroundColor,
      Color textColor,
      Color cardColor,
      Color secondaryTextColor,
      Color accentColor,
      Color dividerColor) {
    return AppBar(
      backgroundColor: backgroundColor,
      elevation: 0,
      centerTitle: false,
      leadingWidth: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: Text(
          _isSelectionMode
              ? '${_selectedNotifications.length} seçildi'
              : 'Bildirimler',
          style: TextStyle(
            color: textColor,
            fontSize: 26,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.3,
          ),
        ),
      ),
      actions: [
        if (_isSelectionMode) ...[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(CupertinoIcons.delete, color: textColor, size: 22),
              tooltip: 'Seçilenleri Sil',
              onPressed: _selectedNotifications.isEmpty
                  ? null
                  : () => _deleteNotifications(_selectedNotifications),
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(CupertinoIcons.clear, color: textColor, size: 22),
              tooltip: 'Seçimi İptal Et',
              onPressed: () {
                setState(() {
                  _isSelectionMode = false;
                  _selectedNotifications.clear();
                });
              },
            ),
          ),
          SizedBox(width: 8),
        ] else ...[
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: Icon(CupertinoIcons.checkmark_rectangle,
                  color: textColor, size: 22),
              tooltip: 'Seçim Modu',
              onPressed: () {
                setState(() => _isSelectionMode = true);
              },
            ),
          ),
          Container(
            margin: EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: IconButton(
              icon: _isLoading
                  ? SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: textColor,
                        strokeWidth: 2,
                      ))
                  : Icon(CupertinoIcons.refresh, color: textColor, size: 22),
              tooltip: 'Yenile',
              onPressed: _isLoading ? null : _loadNotifications,
            ),
          ),
          const SizedBox(width: 12),
        ]
      ],
      bottom: PreferredSize(
        preferredSize: Size.fromHeight(56),
        child: Container(
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: dividerColor.withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
          child: TabBar(
            controller: _tabController,
            indicatorColor: accentColor,
            indicatorWeight: 3,
            indicatorSize: TabBarIndicatorSize.label,
            labelColor: accentColor,
            unselectedLabelColor: secondaryTextColor,
            labelStyle: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
            unselectedLabelStyle: TextStyle(
              fontWeight: FontWeight.normal,
              fontSize: 15,
            ),
            tabs: [
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(CupertinoIcons.bell_fill, size: 16),
                    SizedBox(width: 6),
                    Text('Tümü'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(CupertinoIcons.bell, size: 16),
                        if (unreadCount > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Center(
                                child: Text(
                                  unreadCount > 9 ? '9+' : '$unreadCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 6),
                    Text('Okunmamış'),
                  ],
                ),
              ),
              Tab(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(CupertinoIcons.person_badge_plus_fill, size: 16),
                        if (requestCount > 0)
                          Positioned(
                            right: -6,
                            top: -6,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: AppColors.error,
                                shape: BoxShape.circle,
                              ),
                              constraints: BoxConstraints(
                                minWidth: 14,
                                minHeight: 14,
                              ),
                              child: Center(
                                child: Text(
                                  requestCount > 9 ? '9+' : '$requestCount',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 6),
                    Text('İstekler'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(Color accentColor, Color cardColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            padding: EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: CircularProgressIndicator(
                    color: accentColor,
                    strokeWidth: 3,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Bildirimler yükleniyor...',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Color cardColor, Color textColor,
      Color secondaryTextColor, Color accentColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Container(
          padding: EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 15,
                offset: Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(CupertinoIcons.exclamationmark_triangle,
                    color: AppColors.warning, size: 48),
              ),
              const SizedBox(height: 24),
              Text(
                'Bir Sorun Oluştu',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _errorMessage ?? 'Bildirimler yüklenirken bir hata oluştu.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: secondaryTextColor,
                  fontSize: 16,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadNotifications,
                icon: const Icon(CupertinoIcons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: accentColor,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 5,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState(Color cardColor, Color textColor,
      Color secondaryTextColor, Color accentColor, Color dividerColor) {
    final Icon emptyIcon;
    final String title;
    final String subtitle;
    final Color iconColor;

    switch (_tabController.index) {
      case 1: // Okunmamış
        emptyIcon = Icon(
          CupertinoIcons.bell_slash_fill,
          size: 60,
          color: accentColor.withOpacity(0.6),
        );
        title = 'Okunmamış bildiriminiz yok';
        subtitle =
            'Tüm bildirimleri görüntülemek için "Tümü" sekmesine bakabilirsiniz';
        iconColor = accentColor;
        break;
      case 2: // İstekler
        emptyIcon = Icon(
          CupertinoIcons.person_badge_plus,
          size: 60,
          color: AppColors.success.withOpacity(0.6),
        );
        title = 'Bekleyen takip isteğiniz yok';
        subtitle = 'Biri sizi takip etmek istediğinde burada göreceksiniz';
        iconColor = AppColors.success;
        break;
      default: // Tümü
        emptyIcon = Icon(
          CupertinoIcons.bell_slash_fill,
          size: 60,
          color: secondaryTextColor.withOpacity(0.6),
        );
        title = 'Henüz bildiriminiz yok';
        subtitle = 'Bildirimleriniz burada görünecek';
        iconColor = secondaryTextColor;
    }

    return Center(
      child: Container(
        padding: EdgeInsets.all(30),
        margin: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cardColor.withOpacity(0.7),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: dividerColor,
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: emptyIcon,
            ),
            const SizedBox(height: 24),
            Text(
              title,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              subtitle,
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 16,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
            if (_tabController.index == 0) ...[
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: _loadNotifications,
                icon: Icon(CupertinoIcons.refresh),
                label: Text('Yenile'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textColor,
                  side: BorderSide(color: dividerColor),
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsList(
      Color cardColor,
      Color textColor,
      Color secondaryTextColor,
      Color accentColor,
      Color surfaceColor,
      Color dividerColor) {
    // TabController'ın değişimini dinlemek için addListener ekleyin
    if (!_tabController.hasListeners) {
      _tabController.addListener(() {
        if (_tabController.indexIsChanging) {
          setState(() {
            // Tab değiştiğinde state'i güncelleyin (UI'nin yenilenmesi için)
          });
        }
      });
    }

    List<NotificationModel> filteredNotifications = [];

    switch (_tabController.index) {
      case 0: // Tümü
        filteredNotifications = _notifications;
        break;
      case 1: // Okunmamış
        filteredNotifications = _notifications.where((n) => !n.isRead).toList();
        break;
      case 2: // İstekler
        filteredNotifications = _notifications
            .where((n) =>
                n.type == NotificationType.followRequest && !n.isActionTaken)
            .toList();
        break;
    }

    if (filteredNotifications.isEmpty) {
      return _buildEmptyState(
          cardColor, textColor, secondaryTextColor, accentColor, dividerColor);
    }

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: accentColor,
      backgroundColor: surfaceColor,
      strokeWidth: 3,
      displacement: 40,
      child: ListView.builder(
        itemCount: filteredNotifications.length,
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 10),
        physics: AlwaysScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];

          // Animate notification items
          return AnimatedOpacity(
            opacity: 1.0,
            duration: Duration(milliseconds: 500),
            curve: Curves.easeInOut,
            child: AnimatedSlide(
              offset: Offset.zero,
              duration: Duration(milliseconds: 500),
              curve: Curves.easeInOut,
              child: _buildNotificationItem(notification, cardColor, textColor,
                  secondaryTextColor, accentColor, dividerColor),
            ),
          );
        },
      ),
    );
  }

  Widget _buildNotificationItem(
      NotificationModel notification,
      Color cardColor,
      Color textColor,
      Color secondaryTextColor,
      Color accentColor,
      Color dividerColor) {
    final bool isRead = notification.isRead;
    final bool isActionTaken = notification.isActionTaken;
    final String notificationId = notification.id;
    final bool isSelected = _selectedNotifications.contains(notificationId);

    return Dismissible(
      key: Key(notificationId),
      direction: DismissDirection.endToStart,
      confirmDismiss: (direction) async {
        return await showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              backgroundColor: cardColor,
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
        decoration: BoxDecoration(
          color: Colors.red.shade800,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20.0),
        child: const Icon(
          Icons.delete,
          color: Colors.white,
        ),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(
          color: _getItemBackgroundColor(isRead, isSelected, cardColor),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? Colors.blue.withOpacity(0.5)
                : dividerColor.withOpacity(0.1),
            width: isSelected ? 1.5 : 0.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.blue.withOpacity(0.15),
                    blurRadius: 8,
                    offset: Offset(0, 2),
                  )
                ]
              : null,
        ),
        child: Column(
          children: [
            ListTile(
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
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    )
                  else
                    GestureDetector(
                      onTap: () => notification.actorName != 'Sistem'
                          ? _navigateToUserProfile(notification.actorId)
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: _getNotificationColor(notification),
                            width: 2,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          backgroundColor: Colors.grey[800],
                          backgroundImage: notification.actorAvatar != null
                              ? NetworkImage(notification.actorAvatar!)
                              : null,
                          radius: 24,
                          child: notification.actorAvatar == null
                              ? _getNotificationIcon(notification)
                              : null,
                        ),
                      ),
                    ),
                  if (!isRead && !_isSelectionMode)
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
              title: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: notification.actorName,
                      style: TextStyle(
                        color: Colors.blue,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    TextSpan(
                      text: ' ${_getNotificationText(notification)}',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight:
                            isRead ? FontWeight.normal : FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 14,
                        color: Colors.grey[500],
                      ),
                      SizedBox(width: 4),
                      Text(
                        timeago.format(notification.createdAt, locale: 'tr'),
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 13,
                        ),
                      ),
                      if (_getNotificationCategory(notification) != null) ...[
                        SizedBox(width: 8),
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getNotificationCategoryColor(notification)
                                .withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getNotificationCategory(notification)!,
                            style: TextStyle(
                              color:
                                  _getNotificationCategoryColor(notification),
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (notification.type == NotificationType.comment &&
                      notification.commentText != null)
                    Container(
                      margin: EdgeInsets.only(top: 8),
                      padding: EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.grey[850]?.withOpacity(0.5),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.grey[800]!.withOpacity(0.5),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        notification.commentText!,
                        style: TextStyle(
                          color: Colors.grey[300],
                          fontSize: 13,
                          fontStyle: FontStyle.italic,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
                  : () {
                      // Takip isteği için özel işlem yapma
                      if (notification.type == NotificationType.followRequest) {
                        // Burada bir şey yapma, alt kısımda butonlar var
                      } else {
                        _navigateToContent(notification);
                      }
                    },
              onLongPress: () {
                if (!_isSelectionMode) {
                  setState(() {
                    _isSelectionMode = true;
                    _selectedNotifications.add(notificationId);
                  });
                }
              },
              trailing: notification.type == NotificationType.followRequest &&
                      !isActionTaken
                  ? null // Takip isteği işlemleri alt kısımda yapılacak
                  : null,
            ),

            // Özel işlemler gerektiren bildirim tipleri için alt alanlar
            if (!_isSelectionMode) ...[
              // Takip İsteği
              if (notification.type == NotificationType.followRequest &&
                  !isActionTaken)
                Padding(
                  padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _acceptFollowRequest(
                              notification.actorId, notification.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.blue,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 2,
                          ),
                          child: Text(
                            'Kabul Et',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => _rejectFollowRequest(
                              notification.actorId, notification.id),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.grey),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                          child: Text(
                            'Reddet',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // Yeni cihaz/giriş bildirimlerinde özel butonlar
              if ((notification.type == NotificationType.newLogin ||
                      notification.type == NotificationType.newDevice) &&
                  !isActionTaken)
                Padding(
                  padding: const EdgeInsets.fromLTRB(72, 0, 16, 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () => _confirmDevice(notification.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 2,
                          ),
                          child: Text(
                            'Bu Bendim',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () =>
                              _reportSuspiciousLogin(notification.id),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            elevation: 2,
                          ),
                          child: Text(
                            'Ben Değilim',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }

  // Bildirim kategorisini belirten yardımcı metot (opsiyonel tag için)
  String? _getNotificationCategory(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.likePost:
        return 'Beğeni';
      case NotificationType.comment:
        return 'Yorum';
      case NotificationType.follow:
        return 'Takip';
      case NotificationType.followRequest:
        return 'Takip İsteği';
      case NotificationType.acceptedFollow:
        return 'Takip Onayı';
      case NotificationType.mention:
        return 'Etiket';
      case NotificationType.message:
        return 'Mesaj';
      case NotificationType.newLogin:
      case NotificationType.newDevice:
        return 'Güvenlik';
      default:
        return null;
    }
  }

  // Kategori rengini belirleyen yardımcı metot
  Color _getNotificationCategoryColor(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.likePost:
        return Colors.red.shade400;
      case NotificationType.comment:
        return Colors.blue.shade400;
      case NotificationType.follow:
      case NotificationType.followRequest:
      case NotificationType.acceptedFollow:
        return Colors.green.shade400;
      case NotificationType.mention:
      case NotificationType.tag:
      case NotificationType.postTag:
        return Colors.orange.shade400;
      case NotificationType.message:
        return Colors.purple.shade400;
      case NotificationType.newLogin:
      case NotificationType.newDevice:
        return Colors.amber.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  // Bildirim türüne göre vurgu rengi
  Color _getNotificationColor(NotificationModel notification) {
    switch (notification.type) {
      case NotificationType.likePost:
        return Colors.red.shade400;
      case NotificationType.comment:
        return Colors.blue.shade400;
      case NotificationType.follow:
        return Colors.green.shade400;
      case NotificationType.mention:
        return Colors.orange.shade400;
      case NotificationType.tag:
        return Colors.purple.shade400;
      case NotificationType.followRequest:
        return Colors.lightBlue.shade400;
      case NotificationType.acceptedFollow:
        return Colors.green.shade400;
      case NotificationType.newLogin:
        return Colors.amber.shade400;
      case NotificationType.newDevice:
        return Colors.deepOrange.shade400;
      case NotificationType.postTag:
        return Colors.teal.shade400;
      case NotificationType.message:
        return Colors.indigo.shade400;
      default:
        return Colors.white;
    }
  }

  // Okundu durumuna göre item stilini değiştiren yardımcı metot
  Color _getItemBackgroundColor(bool isRead, bool isSelected, Color cardColor) {
    if (isSelected) return Colors.blue.withOpacity(0.15);
    return isRead ? cardColor : cardColor.withOpacity(0.5);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}
