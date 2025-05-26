import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'package:line_icons/line_icons.dart';
import 'package:social_media/screens/chat_screen.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:social_media/theme/app_theme.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _isLoading = false;
  List<Map<String, dynamic>> _conversations = [];
  bool _hasError = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadSampleConversations();
  }

  void _loadSampleConversations() {
    _conversations = [
      {
        'id': '1',
        'userId': '101',
        'username': 'Ahmet Kaya',
        'userAvatar': 'https://randomuser.me/api/portraits/men/32.jpg',
        'lastMessage': 'Yarınki etkinlik için hazır mısın?',
        'lastMessageTime':
            DateTime.now().subtract(Duration(minutes: 5)).toIso8601String(),
        'unreadCount': 2,
        'isOnline': true,
      },
      {
        'id': '2',
        'userId': '102',
        'username': 'Ayşe Demir',
        'userAvatar': 'https://randomuser.me/api/portraits/women/44.jpg',
        'lastMessage': 'Ödev için kaynak paylaşabilir misin?',
        'lastMessageTime':
            DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
        'unreadCount': 0,
        'isOnline': false,
      },
      {
        'id': '3',
        'userId': '103',
        'username': 'Mehmet Yılmaz',
        'userAvatar': 'https://randomuser.me/api/portraits/men/68.jpg',
        'lastMessage': 'Proje teslim tarihi ertelendi mi?',
        'lastMessageTime':
            DateTime.now().subtract(Duration(hours: 3)).toIso8601String(),
        'unreadCount': 1,
        'isOnline': true,
      },
      {
        'id': '4',
        'userId': '104',
        'username': 'Elif Şahin',
        'userAvatar': 'https://randomuser.me/api/portraits/women/17.jpg',
        'lastMessage': 'Fotoğrafları gördün mü? Harika olmuş!',
        'lastMessageTime':
            DateTime.now().subtract(Duration(days: 1)).toIso8601String(),
        'unreadCount': 0,
        'isOnline': false,
      },
      {
        'id': '5',
        'userId': '105',
        'username': 'Burak Özdemir',
        'userAvatar': 'https://randomuser.me/api/portraits/men/83.jpg',
        'lastMessage': 'Toplantıda görüşelim o zaman.',
        'lastMessageTime':
            DateTime.now().subtract(Duration(days: 2)).toIso8601String(),
        'unreadCount': 0,
        'isOnline': false,
      },
      {
        'id': '6',
        'userId': '106',
        'username': 'Zeynep Çelik',
        'userAvatar': 'https://randomuser.me/api/portraits/women/90.jpg',
        'lastMessage': 'Tebrikler! Başarılarının devamını dilerim.',
        'lastMessageTime':
            DateTime.now().subtract(Duration(days: 3)).toIso8601String(),
        'unreadCount': 0,
        'isOnline': true,
      },
      {
        'id': '7',
        'userId': '107',
        'username': 'Ali Korkmaz',
        'userAvatar': null,
        'lastMessage': 'Sınav sonuçları açıklandı mı?',
        'lastMessageTime':
            DateTime.now().subtract(Duration(days: 5)).toIso8601String(),
        'unreadCount': 0,
        'isOnline': false,
      },
    ];
  }

  Future<void> _loadConversations() async {
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
        Uri.parse('http://192.168.89.61:8080/v1/api/conversations'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _conversations =
              List<Map<String, dynamic>>.from(data['conversations'] ?? []);
          _isLoading = false;
        });
      } else {
        _showError('Sohbetler yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Bağlantı hatası: $e');
    }
  }

  void _showError(String message) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final errorColor =
        themeProvider.isDarkMode ? AppColors.error : AppColors.lightError;

    setState(() {
      _hasError = true;
      _errorMessage = message;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: errorColor,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _navigateToChat(Map<String, dynamic> conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ChatScreen(
          conversationId: conversation['id'],
          userId: conversation['userId'],
          username: conversation['username'],
          userAvatar: conversation['userAvatar'],
        ),
      ),
    );
  }

  void _startNewChat() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor =
        isDarkMode ? AppColors.background : AppColors.lightBackground;
    final cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;
    final secondaryTextColor =
        isDarkMode ? AppColors.secondaryText : AppColors.lightSecondaryText;
    final surfaceColor =
        isDarkMode ? AppColors.surfaceColor : AppColors.lightSurfaceColor;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text(
          'Yeni Sohbet',
          style: TextStyle(color: textColor),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              decoration: InputDecoration(
                hintText: 'Kullanıcı adı ara...',
                hintStyle: TextStyle(color: secondaryTextColor),
                filled: true,
                fillColor: surfaceColor,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: Icon(Icons.search, color: secondaryTextColor),
              ),
              style: TextStyle(color: textColor),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                    'https://randomuser.me/api/portraits/men/42.jpg'),
              ),
              title: Text('Hasan Taş', style: TextStyle(color: textColor)),
              subtitle: Text('@hasantas',
                  style: TextStyle(color: secondaryTextColor)),
              onTap: () {
                Navigator.pop(context);
                final newConversation = {
                  'id': '${_conversations.length + 1}',
                  'userId': '${100 + _conversations.length + 1}',
                  'username': 'Hasan Taş',
                  'userAvatar':
                      'https://randomuser.me/api/portraits/men/42.jpg',
                  'lastMessage': '',
                  'lastMessageTime': DateTime.now().toIso8601String(),
                  'unreadCount': 0,
                  'isOnline': true,
                };

                _navigateToChat(newConversation);
              },
            ),
            ListTile(
              leading: CircleAvatar(
                backgroundImage: NetworkImage(
                    'https://randomuser.me/api/portraits/women/42.jpg'),
              ),
              title: Text('Selin Yılmaz', style: TextStyle(color: textColor)),
              subtitle: Text('@selinyilmaz',
                  style: TextStyle(color: secondaryTextColor)),
              onTap: () {
                Navigator.pop(context);
                final newConversation = {
                  'id': '${_conversations.length + 2}',
                  'userId': '${100 + _conversations.length + 2}',
                  'username': 'Selin Yılmaz',
                  'userAvatar':
                      'https://randomuser.me/api/portraits/women/42.jpg',
                  'lastMessage': '',
                  'lastMessageTime': DateTime.now().toIso8601String(),
                  'unreadCount': 0,
                  'isOnline': false,
                };

                _navigateToChat(newConversation);
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('İptal', style: TextStyle(color: secondaryTextColor)),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(Color backgroundColor, Color surfaceColor,
      Color textColor, Color secondaryTextColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: 'Sohbet ara...',
          hintStyle: TextStyle(color: secondaryTextColor),
          prefixIcon: Icon(Icons.search, color: secondaryTextColor),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: Icon(Icons.close, color: secondaryTextColor),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _isSearching = false;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: surfaceColor,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        onChanged: (value) {
          setState(() {
            _isSearching = value.isNotEmpty;
          });
        },
      ),
    );
  }

  Widget _buildConversationsList(Color backgroundColor, Color cardColor,
      Color textColor, Color secondaryTextColor, Color accentColor) {
    final filteredConversations = _isSearching
        ? _conversations
            .where((conv) =>
                (conv['username'] ?? '')
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase()) ||
                (conv['lastMessage'] ?? '')
                    .toLowerCase()
                    .contains(_searchController.text.toLowerCase()))
            .toList()
        : _conversations;

    return ListView.builder(
      itemCount: filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = filteredConversations[index];
        final bool hasUnreadMessages = conversation['unreadCount'] > 0;
        final DateTime lastMessageTime = DateTime.parse(
            conversation['lastMessageTime'] ??
                DateTime.now().toIso8601String());

        return Dismissible(
          key: Key(conversation['id']),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                final themeProvider =
                    Provider.of<ThemeProvider>(context, listen: false);
                final isDarkMode = themeProvider.isDarkMode;
                final dialogBgColor = isDarkMode
                    ? AppColors.cardBackground
                    : AppColors.lightCardBackground;
                final dialogTextColor = isDarkMode
                    ? AppColors.primaryText
                    : AppColors.lightPrimaryText;
                final dialogSecondaryTextColor = isDarkMode
                    ? AppColors.secondaryText
                    : AppColors.lightSecondaryText;
                final errorColor =
                    isDarkMode ? AppColors.error : AppColors.lightError;

                return AlertDialog(
                  backgroundColor: dialogBgColor,
                  title: Text(
                    'Sohbeti Sil',
                    style: TextStyle(color: dialogTextColor),
                  ),
                  content: Text(
                    'Bu sohbeti silmek istediğinizden emin misiniz?',
                    style: TextStyle(color: dialogSecondaryTextColor),
                  ),
                  actions: <Widget>[
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: Text(
                        'Sil',
                        style: TextStyle(color: errorColor),
                      ),
                    ),
                  ],
                );
              },
            );
          },
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          child: InkWell(
            onTap: () => _navigateToChat(conversation),
            child: Container(
              decoration: BoxDecoration(
                color: backgroundColor,
                border: Border(
                  bottom: BorderSide(
                    color: secondaryTextColor.withOpacity(0.1),
                    width: 0.5,
                  ),
                ),
              ),
              child: ListTile(
                leading: Stack(
                  children: [
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: cardColor,
                      backgroundImage: conversation['userAvatar'] != null
                          ? NetworkImage(conversation['userAvatar'])
                          : null,
                      child: conversation['userAvatar'] == null
                          ? Text(
                              conversation['username']?[0].toUpperCase() ?? '?',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            )
                          : null,
                    ),
                    if (conversation['isOnline'] ?? false)
                      Positioned(
                        right: 0,
                        bottom: 0,
                        child: Container(
                          width: 13,
                          height: 13,
                          decoration: BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: backgroundColor,
                              width: 2,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                title: Row(
                  children: [
                    Expanded(
                      child: Text(
                        conversation['username'] ?? 'Kullanıcı',
                        style: TextStyle(
                          color: textColor,
                          fontWeight: hasUnreadMessages
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      timeago.format(lastMessageTime, locale: 'tr'),
                      style: TextStyle(
                        color: secondaryTextColor,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                subtitle: Row(
                  children: [
                    Expanded(
                      child: Text(
                        conversation['lastMessage'] ?? '',
                        style: TextStyle(
                          color: hasUnreadMessages
                              ? textColor
                              : secondaryTextColor,
                          fontWeight: hasUnreadMessages
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasUnreadMessages)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: accentColor,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          conversation['unreadCount'].toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildLoadingIndicator(Color accentColor) {
    return Center(
      child: CircularProgressIndicator(color: accentColor),
    );
  }

  Widget _buildErrorWidget(Color textColor, Color accentColor, Color errorColor,
      Color secondaryTextColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, color: errorColor, size: 60),
            const SizedBox(height: 16),
            Text(
              'Hata',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: textColor),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Sohbetler yüklenirken bir hata oluştu.',
              textAlign: TextAlign.center,
              style: TextStyle(color: secondaryTextColor),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadConversations,
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
      Color textColor, Color secondaryTextColor, Color accentColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            CupertinoIcons.chat_bubble_2,
            size: 80,
            color: secondaryTextColor,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz mesajınız yok',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(color: textColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Yeni bir sohbet başlatın',
            style: TextStyle(color: secondaryTextColor),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startNewChat,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Sohbet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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

    // Tema bazlı renkler
    final backgroundColor =
        isDarkMode ? AppColors.background : AppColors.lightBackground;
    final cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;
    final secondaryTextColor =
        isDarkMode ? AppColors.secondaryText : AppColors.lightSecondaryText;
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final errorColor = isDarkMode ? AppColors.error : AppColors.lightError;
    final surfaceColor =
        isDarkMode ? AppColors.surfaceColor : AppColors.lightSurfaceColor;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'Mesajlar',
          style: TextStyle(color: textColor),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.add, color: textColor),
            onPressed: _startNewChat,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(
              backgroundColor, surfaceColor, textColor, secondaryTextColor),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator(accentColor)
                : _hasError
                    ? _buildErrorWidget(
                        textColor, accentColor, errorColor, secondaryTextColor)
                    : _conversations.isEmpty
                        ? _buildEmptyState(
                            textColor, secondaryTextColor, accentColor)
                        : _buildConversationsList(backgroundColor, cardColor,
                            textColor, secondaryTextColor, accentColor),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }
}
