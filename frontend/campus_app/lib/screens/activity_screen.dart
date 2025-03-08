import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'package:line_icons/line_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:intl/intl.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({Key? key}) : super(key: key);

  @override
  _ActivityScreenState createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isLoading = true;
  List<Map<String, dynamic>> _notifications = [];
  List<Map<String, dynamic>> _mentions = [];
  bool _hasError = false;
  String? _errorMessage;
  bool _isMarkingAllAsRead = false;

  // Animation controllers
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabChange);
    _loadData();
    
    // Set Turkish locale for timeago
    timeago.setLocaleMessages('tr', timeago.TrMessages());
  }

  void _handleTabChange() {
    if (_tabController.indexIsChanging) {
      _playTabChangeAnimation();
    }
  }

  void _playTabChangeAnimation() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      await Future.wait([
        _loadNotifications(),
        _loadMentions(),
      ]);
      
      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Veri yüklenirken hata oluştu: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadNotifications() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      // Burada gerçek API endpoint'i kullanılacak
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/v1/api/notifications'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _notifications = List<Map<String, dynamic>>.from(data['notifications'] ?? []);
          
          // Sort notifications by date (newest first)
          _notifications.sort((a, b) {
            final DateTime dateA = DateTime.parse(a['createdAt'] ?? DateTime.now().toIso8601String());
            final DateTime dateB = DateTime.parse(b['createdAt'] ?? DateTime.now().toIso8601String());
            return dateB.compareTo(dateA);
          });
        });
      } else {
        throw Exception('Bildirimler alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bildirim yüklenirken hata: $e');
    }
  }

  Future<void> _loadMentions() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      // Burada gerçek API endpoint'i kullanılacak
      final response = await http.get(
        Uri.parse('http://10.0.2.2:8080/v1/api/mentions'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _mentions = List<Map<String, dynamic>>.from(data['mentions'] ?? []);
          
          // Sort mentions by date (newest first)
          _mentions.sort((a, b) {
            final DateTime dateA = DateTime.parse(a['createdAt'] ?? DateTime.now().toIso8601String());
            final DateTime dateB = DateTime.parse(b['createdAt'] ?? DateTime.now().toIso8601String());
            return dateB.compareTo(dateA);
          });
        });
      } else {
        throw Exception('Bahsetmeler alınamadı: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Bahsetmeler yüklenirken hata: $e');
    }
  }

  Future<void> _markAllAsRead() async {
    setState(() {
      _isMarkingAllAsRead = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await http.post(
        Uri.parse('http://10.0.2.2:8080/v1/api/notifications/mark-all-read'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          for (var notification in _notifications) {
            notification['isRead'] = true;
          }
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Tüm bildirimler okundu olarak işaretlendi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Bildirimler okundu olarak işaretlenemedi: ${response.statusCode}');
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
      setState(() {
        _isMarkingAllAsRead = false;
      });
    }
  }

  String _getNotificationText(Map<String, dynamic> notification) {
    String type = notification['type'] ?? 'unknown';
    String actorName = notification['actorName'] ?? 'Bir kullanıcı';
    
    switch (type) {
      case 'like_post':
        return '$actorName gönderinizi beğendi';
      case 'comment':
        return '$actorName gönderinize yorum yaptı';
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

  Widget _getNotificationIcon(Map<String, dynamic> notification, {double size = 24.0}) {
    String type = notification['type'] ?? 'unknown';
    
    switch (type) {
      case 'like_post':
        return Icon(LineIcons.heartAlt, color: Colors.red, size: size);
      case 'comment':
        return Icon(LineIcons.commentAlt, color: Colors.blue, size: size);
      case 'follow':
        return Icon(LineIcons.userPlus, color: Colors.green, size: size);
      case 'mention':
        return Icon(LineIcons.at, color: Colors.orange, size: size);
      case 'tag':
        return Icon(LineIcons.tag, color: Colors.purple, size: size);
      default:
        return Icon(LineIcons.bell, color: Colors.white, size: size);
    }
  }

  Color _getNotificationColor(Map<String, dynamic> notification, {double opacity = 0.15}) {
    String type = notification['type'] ?? 'unknown';
    
    switch (type) {
      case 'like_post':
        return Colors.red.withOpacity(opacity);
      case 'comment':
        return Colors.blue.withOpacity(opacity);
      case 'follow':
        return Colors.green.withOpacity(opacity);
      case 'mention':
        return Colors.orange.withOpacity(opacity);
      case 'tag':
        return Colors.purple.withOpacity(opacity);
      default:
        return Colors.grey.withOpacity(opacity);
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupNotificationsByDate(List<Map<String, dynamic>> notifications) {
    final Map<String, List<Map<String, dynamic>>> grouped = {};
    
    for (var notification in notifications) {
      final DateTime createdAt = DateTime.parse(notification['createdAt'] ?? DateTime.now().toIso8601String());
      final String dateKey = _getDateKey(createdAt);
      
      if (!grouped.containsKey(dateKey)) {
        grouped[dateKey] = [];
      }
      
      grouped[dateKey]!.add(notification);
    }
    
    return grouped;
  }

  String _getDateKey(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateToCheck = DateTime(date.year, date.month, date.day);
    
    if (dateToCheck == today) {
      return 'Bugün';
    } else if (dateToCheck == yesterday) {
      return 'Dün';
    } else if (now.difference(dateToCheck).inDays < 7) {
      return 'Bu Hafta';
    } else if (now.difference(dateToCheck).inDays < 30) {
      return 'Bu Ay';
    } else {
      return DateFormat('MMMM yyyy', 'tr_TR').format(date);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          'Aktivite', 
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 22,
          ),
        ),
        actions: [
          if (_tabController.index == 0 && _notifications.isNotEmpty)
            IconButton(
              icon: _isMarkingAllAsRead 
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Icon(LineIcons.check, color: Colors.white),
              tooltip: 'Tümünü okundu işaretle',
              onPressed: _isMarkingAllAsRead ? null : _markAllAsRead,
            ),
          IconButton(
            icon: const Icon(LineIcons.syncIcon, color: Colors.white),
            tooltip: 'Yenile',
            onPressed: _loadData,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48.0),
          child: Container(
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: Colors.grey.withOpacity(0.1),
                  width: 1.0,
                ),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              indicatorColor: Colors.white,
              labelColor: Colors.white,
              unselectedLabelColor: Colors.grey,
              indicatorWeight: 3.0,
              labelStyle: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LineIcons.bell),
                      SizedBox(width: 8),
                      Text('Bildirimler'),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LineIcons.at),
                      SizedBox(width: 8),
                      Text('Bahsedenler'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _hasError
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildNotificationsTab(),
                    _buildMentionsTab(),
                  ],
                ),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 3,
          ),
          const SizedBox(height: 20),
          Text(
            'Aktiviteleriniz yükleniyor...',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 16,
            ),
          ),
        ],
      ).animate().fade(duration: 400.ms),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              LineIcons.exclamationTriangle, 
              color: Colors.red, 
              size: 80
            ).animate().scale(
              duration: 400.ms,
              curve: Curves.easeOut,
            ),
            const SizedBox(height: 24),
            Text(
              'Hata',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ).animate().fadeIn(delay: 100.ms),
            const SizedBox(height: 12),
            Text(
              _errorMessage ?? 'Aktivite verileri yüklenirken bir hata oluştu.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 16,
              ),
            ).animate().fadeIn(delay: 200.ms),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _loadData,
              icon: const Icon(LineIcons.syncIcon),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
            ).animate().fadeIn(delay: 300.ms).moveY(begin: 20, end: 0),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationsTab() {
    if (_notifications.isEmpty) {
      return _buildEmptyState(
        'Henüz bildiriminiz yok', 
        'Bildirimleriniz burada görünecek', 
        LineIcons.bellSlash
      );
    }

    final groupedNotifications = _groupNotificationsByDate(_notifications);
    final dateKeys = groupedNotifications.keys.toList();

    return RefreshIndicator(
      onRefresh: _loadNotifications,
      color: Colors.white,
      backgroundColor: Colors.blue,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: dateKeys.length,
        itemBuilder: (context, sectionIndex) {
          final dateKey = dateKeys[sectionIndex];
          final sectionNotifications = groupedNotifications[dateKey]!;
          
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(
                  dateKey,
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              ListView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                itemCount: sectionNotifications.length,
                itemBuilder: (context, index) {
                  final notification = sectionNotifications[index];
                  final bool isRead = notification['isRead'] ?? false;
                  final DateTime createdAt = DateTime.parse(notification['createdAt'] ?? DateTime.now().toIso8601String());
                  final String profilePhoto = notification['profilePhoto'] ?? '';
                  
                  return Container(
                    decoration: BoxDecoration(
                      color: isRead ? Colors.transparent : _getNotificationColor(notification, opacity: 0.1),
                      border: Border(
                        bottom: BorderSide(
                          color: Colors.grey.withOpacity(0.1),
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Dismissible(
                      key: Key('notification_${notification['id']}'),
                      background: Container(
                        color: Colors.red,
                        alignment: Alignment.centerRight,
                        padding: EdgeInsets.only(right: 20.0),
                        child: Icon(LineIcons.trash, color: Colors.white),
                      ),
                      direction: DismissDirection.endToStart,
                      onDismissed: (direction) {
                        // Implement notification dismissal logic
                        setState(() {
                          sectionNotifications.removeAt(index);
                          if (sectionNotifications.isEmpty) {
                            groupedNotifications.remove(dateKey);
                          }
                        });
                        
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Bildirim silindi'),
                            action: SnackBarAction(
                              label: 'Geri Al',
                              onPressed: () {
                                setState(() {
                                  if (!groupedNotifications.containsKey(dateKey)) {
                                    groupedNotifications[dateKey] = [];
                                  }
                                  sectionNotifications.insert(index, notification);
                                });
                              },
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      child: InkWell(
                        onTap: () {
                          // Bildirime tıklandığında ilgili sayfaya yönlendirme yapılabilir
                          // Örneğin: Navigator.pushNamed(context, '/post/${notification['postId']}');
                          
                          // Bildirimi okundu olarak işaretleme
                          setState(() {
                            notification['isRead'] = true;
                          });
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              // Avatar or Icon
                              Stack(
                                children: [
                                  Container(
                                    width: 50,
                                    height: 50,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _getNotificationColor(notification, opacity: 0.2),
                                    ),
                                    child: profilePhoto.isNotEmpty
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(25),
                                            child: Image.network(
                                              profilePhoto,
                                              fit: BoxFit.cover,
                                              errorBuilder: (context, error, stackTrace) => 
                                                  _getNotificationIcon(notification, size: 30),
                                            ),
                                          )
                                        : _getNotificationIcon(notification, size: 30),
                                  ),
                                  if (!isRead)
                                    Positioned(
                                      right: 0,
                                      top: 0,
                                      child: Container(
                                        width: 12,
                                        height: 12,
                                        decoration: BoxDecoration(
                                          color: Colors.blue,
                                          shape: BoxShape.circle,
                                          border: Border.all(color: Colors.black, width: 2),
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(width: 16),
                              // Content
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _getNotificationText(notification),
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: isRead ? FontWeight.normal : FontWeight.bold,
                                        fontSize: 15,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      timeago.format(createdAt, locale: 'tr'),
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 13,
                                      ),
                                    ),
                                    if (notification['text'] != null && notification['text'].isNotEmpty)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 8.0),
                                        child: Container(
                                          padding: EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: Colors.grey.withOpacity(0.1),
                                            borderRadius: BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            notification['text'],
                                            style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 14,
                                              fontStyle: FontStyle.italic,
                                            ),
                                            maxLines: 2,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                              // Post Image if any
                              if (notification['postImage'] != null)
                                Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      width: 56,
                                      height: 56,
                                      decoration: BoxDecoration(
                                        image: DecorationImage(
                                          image: NetworkImage(notification['postImage']),
                                          fit: BoxFit.cover,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(
                    duration: 300.ms,
                    delay: (index * 30).ms,
                  );
                },
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMentionsTab() {
    if (_mentions.isEmpty) {
      return _buildEmptyState(
        'Kimse sizi etiketlemedi', 
        'Etiketlendiğiniz gönderiler burada görünecek', 
        LineIcons.at
      );
    }

    return RefreshIndicator(
      onRefresh: _loadMentions,
      color: Colors.white,
      backgroundColor: Colors.blue,
      child: ListView.builder(
        controller: _scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        itemCount: _mentions.length,
        itemBuilder: (context, index) {
          final mention = _mentions[index];
          final String username = mention['username'] ?? 'Kullanıcı';
          final String text = mention['text'] ?? '';
          final DateTime createdAt = DateTime.parse(mention['createdAt'] ?? DateTime.now().toIso8601String());
          final String profilePhoto = mention['profilePhoto'] ?? '';
          final String postImage = mention['postImage'] ?? '';
          
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: Colors.grey.withOpacity(0.1),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            elevation: 0,
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                // Bahsetmeye tıklandığında ilgili gönderi sayfasına git
              },
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header section with user info
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.grey[800],
                          backgroundImage: profilePhoto.isNotEmpty ? NetworkImage(profilePhoto) : null,
                          child: profilePhoto.isEmpty ? Icon(LineIcons.userCircle, color: Colors.white) : null,
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              username,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              timeago.format(createdAt, locale: 'tr'),
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Spacer(),
                        Icon(LineIcons.angleRight, color: Colors.grey),
                      ],
                    ),
                    
                    // Mention content
                    if (text.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 12.0),
                        child: Text(
                          text,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                          ),
                        ),
                      ),
                    
                    // Post image if available
                    if (postImage.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            postImage,
                            height: 200,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    
                    // Action buttons
                    Padding(
                      padding: const EdgeInsets.only(top: 16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          TextButton.icon(
                            onPressed: () {
                              // Reply action
                            },
                            icon: Icon(LineIcons.reply, size: 18, color: Colors.blue),
                            label: Text(
                              'Yanıtla',
                              style: TextStyle(color: Colors.blue),
                            ),
                            style: TextButton.styleFrom(
                              backgroundColor: Colors.blue.withOpacity(0.1),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                          ),
                          IconButton(
                            icon: Icon(LineIcons.share, color: Colors.grey),
                            onPressed: () {
                              // Share action
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ).animate().fadeIn(
            duration: 300.ms,
            delay: (index * 50).ms,
          ).slide(begin: Offset(0, 0.1), end: Offset.zero);
        },
      ),
    );
  }

  Widget _buildEmptyState(String title, String subtitle, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            size: 100,
            color: Colors.white38,
          ).animate().scale(
            duration: 500.ms,
            curve: Curves.elasticOut,
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ).animate().fadeIn(delay: 200.ms),
          const SizedBox(height: 12),
          Text(
            subtitle,
            style: TextStyle(color: Colors.white60, fontSize: 16),
            textAlign: TextAlign.center,
          ).animate().fadeIn(delay: 300.ms),
          const SizedBox(height: 40),
          ElevatedButton.icon(
            onPressed: _loadData,
            icon: Icon(LineIcons.syncIcon),
            label: Text('Yenile'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ).animate().fadeIn(delay: 400.ms).moveY(begin: 20, end: 0),
        ],
      ),
    );
  }
} //flutter pub add flutter_animate