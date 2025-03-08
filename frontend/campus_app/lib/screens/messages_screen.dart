import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'package:line_icons/line_icons.dart';

class MessagesScreen extends StatefulWidget {
  const MessagesScreen({Key? key}) : super(key: key);

  @override
  _MessagesScreenState createState() => _MessagesScreenState();
}

class _MessagesScreenState extends State<MessagesScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _conversations = [];
  bool _hasError = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadConversations();
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
        Uri.parse('http://localhost:8080/v1/api/conversations'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _conversations = List<Map<String, dynamic>>.from(data['conversations'] ?? []);
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

  void _navigateToChat(Map<String, dynamic> conversation) {
    Navigator.pushNamed(
      context,
      '/chat/${conversation['id']}',
      arguments: {
        'userId': conversation['userId'],
        'username': conversation['username'],
        'userAvatar': conversation['userAvatar'],
      },
    );
  }

  void _startNewChat() {
    Navigator.pushNamed(context, '/new-chat');
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Sohbet ara...',
          hintStyle: TextStyle(color: Colors.grey[400]),
          prefixIcon: const Icon(Icons.search, color: Colors.grey),
          suffixIcon: _isSearching
              ? IconButton(
                  icon: const Icon(Icons.close, color: Colors.grey),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _isSearching = false;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: Colors.grey[900],
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(30),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        ),
        onChanged: (value) {
          setState(() {
            _isSearching = value.isNotEmpty;
          });
        },
      ),
    );
  }

  Widget _buildConversationsList() {
    final filteredConversations = _isSearching
        ? _conversations.where((conv) =>
            (conv['username'] ?? '').toLowerCase().contains(_searchController.text.toLowerCase()) ||
            (conv['lastMessage'] ?? '').toLowerCase().contains(_searchController.text.toLowerCase()))
        .toList()
        : _conversations;

    return ListView.builder(
      itemCount: filteredConversations.length,
      itemBuilder: (context, index) {
        final conversation = filteredConversations[index];
        final bool hasUnreadMessages = conversation['unreadCount'] > 0;
        final DateTime lastMessageTime = DateTime.parse(conversation['lastMessageTime'] ?? DateTime.now().toIso8601String());

        return Dismissible(
          key: Key(conversation['id']),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text(
                    'Sohbeti Sil',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: const Text(
                    'Bu sohbeti silmek istediğinizden emin misiniz?',
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
          background: Container(
            color: Colors.red,
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.only(right: 20.0),
            child: const Icon(
              Icons.delete,
              color: Colors.white,
            ),
          ),
          child: InkWell(
            onTap: () => _navigateToChat(conversation),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black,
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
                    CircleAvatar(
                      radius: 25,
                      backgroundColor: Colors.grey[800],
                      backgroundImage: conversation['userAvatar'] != null
                          ? NetworkImage(conversation['userAvatar'])
                          : null,
                      child: conversation['userAvatar'] == null
                          ? Text(
                              conversation['username']?[0].toUpperCase() ?? '?',
                              style: const TextStyle(
                                color: Colors.white,
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
                              color: Colors.black,
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
                          color: Colors.white,
                          fontWeight: hasUnreadMessages ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                    Text(
                      timeago.format(lastMessageTime, locale: 'tr'),
                      style: TextStyle(
                        color: Colors.grey[600],
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
                          color: hasUnreadMessages ? Colors.white : Colors.grey[600],
                          fontWeight: hasUnreadMessages ? FontWeight.w500 : FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (hasUnreadMessages)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: const BoxDecoration(
                          color: Colors.blue,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          conversation['unreadCount'].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                  ],
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
            ),
          ),
        );
      },
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
              _errorMessage ?? 'Sohbetler yüklenirken bir hata oluştu.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadConversations,
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
            CupertinoIcons.chat_bubble_2,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            'Henüz mesajınız yok',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Yeni bir sohbet başlatın',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _startNewChat,
            icon: const Icon(Icons.add),
            label: const Text('Yeni Sohbet'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text(
          'Mesajlar',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: _startNewChat,
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchBar(),
          Expanded(
            child: _isLoading
                ? _buildLoadingIndicator()
                : _hasError
                    ? _buildErrorWidget()
                    : _conversations.isEmpty
                        ? _buildEmptyState()
                        : _buildConversationsList(),
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