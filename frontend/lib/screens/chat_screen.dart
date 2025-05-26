import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'package:line_icons/line_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';

class ChatScreen extends StatefulWidget {
  final String conversationId;
  final String userId;
  final String username;
  final String? userAvatar;

  const ChatScreen({
    Key? key,
    required this.conversationId,
    required this.userId,
    required this.username,
    this.userAvatar,
  }) : super(key: key);

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final ImagePicker _imagePicker = ImagePicker();

  List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false; // Changed to false to start with sample data
  bool _isSending = false;
  bool _isTyping = false;
  bool _showScrollButton = false;
  String? _errorMessage;
  File? _selectedImage;
  bool _isRecording = false;
  String? _recordingPath;
  bool _showEmojiPicker = false;
  String _currentUserId = "999"; // Mock current user ID for sample data

  @override
  void initState() {
    super.initState();
    _loadSampleMessages(); // Load sample messages instead of API call
    _setupScrollListener();
  }

  // Sample messages for demonstration
  void _loadSampleMessages() {
    // Add some delay to simulate loading
    Future.delayed(Duration(milliseconds: 300), () {
      setState(() {
        _messages = [
          {
            'id': '1',
            'senderId': widget.userId,
            'text': 'Merhaba! Nasılsın?',
            'createdAt': DateTime.now()
                .subtract(Duration(days: 1, hours: 2))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': '2',
            'senderId': _currentUserId,
            'text': 'İyiyim, teşekkürler. Sen nasılsın?',
            'createdAt': DateTime.now()
                .subtract(Duration(days: 1, hours: 2))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': '3',
            'senderId': widget.userId,
            'text': 'Ben de iyiyim. Dersler nasıl gidiyor?',
            'createdAt': DateTime.now()
                .subtract(Duration(days: 1, hours: 1))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': '4',
            'senderId': _currentUserId,
            'text':
                'Dersler yoğun ama keyifli. Finallere hazırlanıyorum şu sıralar.',
            'createdAt': DateTime.now()
                .subtract(Duration(days: 1, hours: 1))
                .toIso8601String(),
            'isRead': true,
          },
          {
            'id': '5',
            'senderId': widget.userId,
            'text': 'Hangi dersleri alıyorsun bu dönem?',
            'createdAt':
                DateTime.now().subtract(Duration(hours: 5)).toIso8601String(),
            'isRead': true,
          },
          {
            'id': '6',
            'senderId': _currentUserId,
            'text':
                'Veri Yapıları, Algoritma Analizi ve Mobil Programlama. Sen?',
            'createdAt':
                DateTime.now().subtract(Duration(hours: 5)).toIso8601String(),
            'isRead': true,
          },
          {
            'id': '7',
            'senderId': widget.userId,
            'imageUrl': 'https://picsum.photos/id/1002/400/300',
            'text': 'Kampüste çektiğim bir fotoğraf. Güzel olmuş mu?',
            'createdAt':
                DateTime.now().subtract(Duration(hours: 2)).toIso8601String(),
            'isRead': true,
          },
          {
            'id': '8',
            'senderId': _currentUserId,
            'text': 'Harika görünüyor! Ne zaman çektin bunu?',
            'createdAt':
                DateTime.now().subtract(Duration(hours: 1)).toIso8601String(),
            'isRead': true,
          },
          {
            'id': '9',
            'senderId': widget.userId,
            'text':
                'Dün akşam gün batımında. Bu arada yarınki etkinlik için hazır mısın?',
            'createdAt': DateTime.now()
                .subtract(Duration(minutes: 30))
                .toIso8601String(),
            'isRead': true,
          },
        ];

        _scrollToBottom();
      });
    });
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      setState(() {
        _showScrollButton = _scrollController.offset > 1000;
      });

      // Sonsuz yükleme için
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMoreMessages();
      }
    });
  }

  Future<void> _loadMoreMessages() async {
    // Implement real API call later
  }

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      _isLoading = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _sendMessage(
      {String? text, File? image, String? audioPath}) async {
    if ((text?.isEmpty ?? true) && image == null && audioPath == null) return;

    setState(() => _isSending = true);

    try {
      // Create a new message with local data
      final newMessage = {
        'id': DateTime.now().millisecondsSinceEpoch.toString(),
        'senderId': _currentUserId, // Current user is sending
        'text': text,
        'createdAt': DateTime.now().toIso8601String(),
        'isRead': false,
      };

      if (image != null) {
        // For demo, we're just pretending to upload the image
        // In a real app, you would upload to server
        newMessage['imageUrl'] =
            'https://picsum.photos/id/${1000 + _messages.length}/400/300';
      }

      if (audioPath != null) {
        // For demo, we're just pretending to upload the audio
        newMessage['audioUrl'] = 'audio_sample_url';
      }

      // Add short delay to simulate network call
      await Future.delayed(Duration(milliseconds: 500));

      setState(() {
        _messages.add(newMessage);
        _messageController.clear();
        _selectedImage = null;
        _recordingPath = null;
        _isSending = false;
      });

      _scrollToBottom();
    } catch (e) {
      setState(() => _isSending = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesaj gönderilemedi'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickImage() async {
    final XFile? image = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 70,
    );

    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<void> _takePhoto() async {
    final XFile? photo = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 70,
    );

    if (photo != null) {
      setState(() {
        _selectedImage = File(photo.path);
      });
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  Future<void> _deleteMessage(String messageId) async {
    try {
      // For demo, delete the message directly
      setState(() {
        _messages.removeWhere((m) => m['id'] == messageId);
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesaj silindi'),
          backgroundColor: Theme.of(context).colorScheme.tertiary,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Mesaj silinemedi'),
          backgroundColor: Theme.of(context).colorScheme.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Widget _buildMessageInput(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          top: BorderSide(
            color: theme.colorScheme.outline.withOpacity(0.1),
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.05),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_selectedImage != null)
              Container(
                height: 100,
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.file(
                          _selectedImage!,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surface.withOpacity(0.7),
                          shape: BoxShape.circle,
                        ),
                        child: IconButton(
                          icon: Icon(Icons.close,
                              color: theme.colorScheme.onSurface, size: 16),
                          onPressed: () {
                            setState(() {
                              _selectedImage = null;
                            });
                          },
                          constraints: BoxConstraints(
                            minWidth: 32,
                            minHeight: 32,
                          ),
                          padding: EdgeInsets.zero,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  margin: EdgeInsets.only(right: 4),
                  child: IconButton(
                    icon: Icon(Icons.add_photo_alternate,
                        color: theme.colorScheme.primary, size: 20),
                    onPressed: _pickImage,
                    padding: EdgeInsets.all(8),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  margin: EdgeInsets.only(right: 4),
                  child: IconButton(
                    icon: Icon(Icons.camera_alt,
                        color: theme.colorScheme.primary, size: 20),
                    onPressed: _takePhoto,
                    padding: EdgeInsets.all(8),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  margin: EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: Icon(
                      _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
                      color: theme.colorScheme.primary,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _showEmojiPicker = !_showEmojiPicker;
                      });
                    },
                    padding: EdgeInsets.all(8),
                  ),
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: TextStyle(color: theme.colorScheme.onSurface),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Mesaj yazın...',
                      hintStyle: TextStyle(
                          color: theme.colorScheme.onSurface.withOpacity(0.6)),
                      filled: true,
                      fillColor:
                          theme.colorScheme.surfaceVariant.withOpacity(0.5),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                    ),
                    onChanged: (value) {
                      // Yazıyor durumunu API'ye bildir
                    },
                  ),
                ),
                SizedBox(width: 8),
                Container(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: _isSending
                        ? SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary),
                            ),
                          )
                        : Icon(Icons.send,
                            color: theme.colorScheme.onPrimary, size: 20),
                    onPressed: _isSending
                        ? null
                        : () => _sendMessage(text: _messageController.text),
                    padding: EdgeInsets.all(8),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message, ThemeData theme) {
    final bool isMe = message['senderId'] == _currentUserId;
    final DateTime messageTime = DateTime.parse(message['createdAt']);
    final bool hasImage = message['imageUrl'] != null;
    final bool hasAudio = message['audioUrl'] != null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 80 : 12,
          right: isMe ? 12 : 80,
          top: 4,
          bottom: 4,
        ),
        decoration: BoxDecoration(
          color: isMe
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: theme.shadowColor.withOpacity(0.1),
              blurRadius: 4,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: InkWell(
          onLongPress: isMe ? () => _showMessageOptions(message, theme) : null,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  GestureDetector(
                    onTap: () => _showImageFullScreen(message['imageUrl']),
                    child: Container(
                      margin: EdgeInsets.only(bottom: 8),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          message['imageUrl'],
                          fit: BoxFit.cover,
                          width: 200,
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              width: 200,
                              height: 150,
                              alignment: Alignment.center,
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes !=
                                        null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                                color: theme.colorScheme.primary,
                                strokeWidth: 2,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                  ),
                if (hasAudio)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isMe
                          ? theme.colorScheme.primary.withOpacity(0.8)
                          : theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            Icons.play_arrow,
                            color: isMe
                                ? theme.colorScheme.onPrimary
                                : theme.colorScheme.primary,
                            size: 24,
                          ),
                          onPressed: () {
                            // Ses dosyasını oynat
                          },
                        ),
                        Container(
                          width: 100,
                          height: 2,
                          color: isMe
                              ? theme.colorScheme.onPrimary.withOpacity(0.5)
                              : theme.colorScheme.primary.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                if (message['text'] != null)
                  Padding(
                    padding: const EdgeInsets.all(4),
                    child: Text(
                      message['text'],
                      style: TextStyle(
                        color: isMe
                            ? theme.colorScheme.onPrimary
                            : theme.colorScheme.onSurface,
                        fontSize: 16,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeago.format(messageTime, locale: 'tr'),
                        style: TextStyle(
                          color: isMe
                              ? theme.colorScheme.onPrimary.withOpacity(0.7)
                              : theme.colorScheme.onSurface.withOpacity(0.7),
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message['isRead'] ?? false
                              ? Icons.done_all
                              : Icons.done,
                          size: 14,
                          color: message['isRead'] ?? false
                              ? isMe
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.primary
                              : isMe
                                  ? theme.colorScheme.onPrimary.withOpacity(0.7)
                                  : theme.colorScheme.onSurface
                                      .withOpacity(0.7),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showMessageOptions(Map<String, dynamic> message, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              margin: EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withOpacity(0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: Icon(Icons.copy, color: theme.colorScheme.primary),
              title: Text(
                'Kopyala',
                style: TextStyle(color: theme.colorScheme.onSurface),
              ),
              onTap: () {
                // Mesajı panoya kopyala
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: Icon(Icons.delete, color: theme.colorScheme.error),
              title: Text(
                'Sil',
                style: TextStyle(color: theme.colorScheme.error),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(message['id'], theme);
              },
            ),
            SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String messageId, ThemeData theme) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: theme.colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Mesajı Sil',
          style: TextStyle(color: theme.colorScheme.onSurface),
        ),
        content: Text(
          'Bu mesajı silmek istediğinizden emin misiniz?',
          style: TextStyle(color: theme.colorScheme.onSurface.withOpacity(0.8)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.primary,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            style: TextButton.styleFrom(
              foregroundColor: theme.colorScheme.error,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Sil'),
          ),
        ],
      ),
    );
  }

  void _showImageFullScreen(String imageUrl) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final theme = themeProvider.currentTheme;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: theme.colorScheme.background,
          appBar: AppBar(
            backgroundColor: theme.colorScheme.background,
            iconTheme: IconThemeData(color: theme.colorScheme.onBackground),
            elevation: 0,
          ),
          body: Center(
            child: InteractiveViewer(
              child: Hero(
                tag: imageUrl,
                child: Image.network(
                  imageUrl,
                  loadingBuilder: (context, child, loadingProgress) {
                    if (loadingProgress == null) return child;
                    return Center(
                      child: CircularProgressIndicator(
                        value: loadingProgress.expectedTotalBytes != null
                            ? loadingProgress.cumulativeBytesLoaded /
                                loadingProgress.expectedTotalBytes!
                            : null,
                        color: theme.colorScheme.primary,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.colorScheme.background,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.surface,
        elevation: 0,
        title: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: theme.colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: CircleAvatar(
                radius: 18,
                backgroundColor: theme.colorScheme.surface,
                backgroundImage: widget.userAvatar != null
                    ? NetworkImage(widget.userAvatar!)
                    : null,
                child: widget.userAvatar == null
                    ? Text(
                        widget.username[0].toUpperCase(),
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.bold,
                        ),
                      )
                    : null,
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: TextStyle(
                    color: theme.colorScheme.onSurface,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 0.3,
                  ),
                ),
                if (_isTyping)
                  Text(
                    'yazıyor...',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant,
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18),
            color: theme.colorScheme.onSurface,
            onPressed: () => Navigator.pop(context),
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceVariant,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: Icon(Icons.more_vert, size: 20),
              color: theme.colorScheme.onSurface,
              onPressed: () {
                // Sohbet ayarları menüsü
                showModalBottomSheet(
                  context: context,
                  backgroundColor: theme.colorScheme.surface,
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => SafeArea(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 4,
                          margin: EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.onSurface.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                        ListTile(
                          leading: Icon(Icons.block,
                              color: theme.colorScheme.onSurface),
                          title: Text(
                            'Kullanıcıyı Engelle',
                            style:
                                TextStyle(color: theme.colorScheme.onSurface),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Kullanıcı engellendi'),
                                backgroundColor: theme.colorScheme.tertiary,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                        ListTile(
                          leading: Icon(Icons.delete_sweep,
                              color: theme.colorScheme.error),
                          title: Text(
                            'Sohbeti Temizle',
                            style: TextStyle(color: theme.colorScheme.error),
                          ),
                          onTap: () {
                            Navigator.pop(context);
                            // Confirm deletion
                            showDialog(
                              context: context,
                              builder: (context) => AlertDialog(
                                backgroundColor: theme.colorScheme.surface,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                title: Text(
                                  'Sohbeti Temizle',
                                  style: TextStyle(
                                      color: theme.colorScheme.onSurface),
                                ),
                                content: Text(
                                  'Tüm mesajlar silinecek. Devam etmek istiyor musunuz?',
                                  style: TextStyle(
                                      color: theme.colorScheme.onSurface
                                          .withOpacity(0.8)),
                                ),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context),
                                    style: TextButton.styleFrom(
                                      foregroundColor:
                                          theme.colorScheme.primary,
                                    ),
                                    child: Text('İptal'),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      setState(() {
                                        _messages = [];
                                      });
                                      Navigator.pop(context);
                                    },
                                    style: TextButton.styleFrom(
                                      foregroundColor: theme.colorScheme.error,
                                    ),
                                    child: Text('Temizle'),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                        SizedBox(height: 16),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.colorScheme.surface,
              theme.colorScheme.background,
            ],
            stops: const [0.0, 0.2],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    _isLoading
                        ? Center(
                            child: CircularProgressIndicator(
                                color: theme.colorScheme.primary),
                          )
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 12),
                            itemCount: _messages.length,
                            itemBuilder: (context, index) {
                              return _buildMessage(_messages[index], theme);
                            },
                          ),
                    if (_showScrollButton)
                      Positioned(
                        right: 16,
                        bottom: 16,
                        child: FloatingActionButton(
                          mini: true,
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: theme.colorScheme.onPrimary,
                          elevation: 2,
                          child: const Icon(Icons.arrow_downward, size: 20),
                          onPressed: _scrollToBottom,
                        ),
                      ),
                  ],
                ),
              ),
              _buildMessageInput(theme),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }
}
