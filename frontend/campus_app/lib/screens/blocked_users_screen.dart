import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:line_icons/line_icons.dart';
import 'package:timeago/timeago.dart' as timeago;

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  _BlockedUsersScreenState createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  bool _isLoading = true;
  List<Map<String, dynamic>> _blockedUsers = [];
  bool _hasError = false;
  String? _errorMessage;
  final TextEditingController _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/api/users/blocked'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _blockedUsers = List<Map<String, dynamic>>.from(data['blockedUsers'] ?? []);
          _isLoading = false;
        });
      } else {
        _showError('Engellenen kullanıcılar alınamadı: ${response.statusCode}');
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

  Future<void> _blockUser(String userId, String username) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await http.post(
        Uri.parse('http://localhost:8080/v1/api/users/block/$userId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        _loadBlockedUsers();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$username engellendi'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Kullanıcı engellenemedi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _unblockUser(String userId, int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await http.delete(
        Uri.parse('http://localhost:8080/v1/api/users/block/$userId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _blockedUsers.removeAt(index);
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Kullanıcının engeli kaldırıldı'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        throw Exception('Engel kaldırılamadı');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Hata: $e'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showUnblockConfirmation(String userId, String userName, int index) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Engeli Kaldır',
            style: TextStyle(color: Colors.white),
          ),
          content: Text(
            '$userName adlı kullanıcının engelini kaldırmak istediğinize emin misiniz?',
            style: const TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'İptal',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _unblockUser(userId, index);
              },
              child: const Text(
                'Engeli Kaldır',
                style: TextStyle(color: Colors.blue),
              ),
            ),
          ],
        );
      },
    );
  }

  void _showBlockUserDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text(
            'Kullanıcı Engelle',
            style: TextStyle(color: Colors.white),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Kullanıcı adı veya ID',
                  hintStyle: TextStyle(color: Colors.grey[400]),
                  filled: true,
                  fillColor: Colors.grey[800],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'İptal',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () {
                // Kullanıcıyı engelle
                Navigator.of(context).pop();
              },
              child: const Text(
                'Engelle',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildSearchBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          hintText: 'Engellenen kullanıcılarda ara...',
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

  Widget _buildBlockedUsersList() {
    final filteredUsers = _isSearching
        ? _blockedUsers.where((user) =>
            (user['userName'] ?? '').toLowerCase().contains(_searchController.text.toLowerCase()) ||
            (user['fullName'] ?? '').toLowerCase().contains(_searchController.text.toLowerCase()))
        .toList()
        : _blockedUsers;

    return ListView.builder(
      itemCount: filteredUsers.length,
      itemBuilder: (context, index) {
        final user = filteredUsers[index];
        final String userId = user['userId'] ?? '';
        final String userName = user['userName'] ?? 'Kullanıcı';
        final String fullName = user['fullName'] ?? '';
        final String profilePhoto = user['profilePhoto'] ?? '';
        final DateTime blockDate = DateTime.parse(user['blockDate'] ?? DateTime.now().toIso8601String());
        
        return Dismissible(
          key: Key(userId),
          direction: DismissDirection.endToStart,
          confirmDismiss: (direction) async {
            return await showDialog(
              context: context,
              builder: (BuildContext context) {
                return AlertDialog(
                  backgroundColor: Colors.grey[900],
                  title: const Text(
                    'Engeli Kaldır',
                    style: TextStyle(color: Colors.white),
                  ),
                  content: Text(
                    '$userName kullanıcısının engelini kaldırmak istediğinize emin misiniz?',
                    style: const TextStyle(color: Colors.white70),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('İptal'),
                    ),
                    TextButton(
                      onPressed: () => Navigator.of(context).pop(true),
                      child: const Text(
                        'Engeli Kaldır',
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
              Icons.block,
              color: Colors.white,
            ),
          ),
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
                    backgroundImage: profilePhoto.isNotEmpty
                        ? NetworkImage(profilePhoto)
                        : null,
                    child: profilePhoto.isEmpty
                        ? Text(
                            userName[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        : null,
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 15,
                      height: 15,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.black,
                          width: 2,
                        ),
                      ),
                      child: const Icon(
                        Icons.block,
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              title: Text(
                fullName.isNotEmpty ? fullName : userName,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '@$userName',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Engellenme tarihi: ${timeago.format(blockDate, locale: 'tr')}',
                    style: TextStyle(
                      color: Colors.grey[500],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
              trailing: TextButton.icon(
                onPressed: () => _showUnblockConfirmation(userId, userName, index),
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.blue,
                  size: 20,
                ),
                label: const Text(
                  'Engeli Kaldır',
                  style: TextStyle(
                    color: Colors.blue,
                    fontSize: 13,
                  ),
                ),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
              _errorMessage ?? 'Engellenen kullanıcılar yüklenirken bir hata oluştu.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadBlockedUsers,
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
            CupertinoIcons.person_crop_circle_badge_xmark,
            size: 80,
            color: Colors.white54,
          ),
          const SizedBox(height: 16),
          Text(
            'Engellediğiniz kullanıcı yok',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Engellenmiş kullanıcılar burada görünecek',
            style: TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: _showBlockUserDialog,
            icon: const Icon(Icons.person_add_disabled),
            label: const Text('Kullanıcı Engelle'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
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
          'Engellenen Kullanıcılar',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person_add_disabled, color: Colors.white),
            onPressed: _showBlockUserDialog,
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadBlockedUsers,
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
                    : _blockedUsers.isEmpty
                        ? _buildEmptyState()
                        : _buildBlockedUsersList(),
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