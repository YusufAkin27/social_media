import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:timeago/timeago.dart' as timeago;
import 'package:line_icons/line_icons.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

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
  bool _isLoading = true;
  bool _isSending = false;
  bool _isTyping = false;
  bool _showScrollButton = false;
  String? _errorMessage;
  File? _selectedImage;
  bool _isRecording = false;
  String? _recordingPath;
  bool _showEmojiPicker = false;

  @override
  void initState() {
    super.initState();
    _loadMessages();
    _setupScrollListener();
    _startMessageListener();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      setState(() {
        _showScrollButton = _scrollController.offset > 1000;
      });
      
      // Sonsuz yükleme için
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMoreMessages();
      }
    });
  }

  Future<void> _loadMessages() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/api/conversations/${widget.conversationId}/messages'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          _messages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
          _isLoading = false;
        });
        _scrollToBottom();
      } else {
        _showError('Mesajlar yüklenemedi: ${response.statusCode}');
      }
    } catch (e) {
      _showError('Bağlantı hatası: $e');
    }
  }

  Future<void> _loadMoreMessages() async {
    if (_isLoading || _messages.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      final lastMessageId = _messages.first['id'];
      
      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/api/conversations/${widget.conversationId}/messages?before=$lastMessageId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final newMessages = List<Map<String, dynamic>>.from(data['messages'] ?? []);
        
        setState(() {
          _messages.insertAll(0, newMessages);
        });
      }
    } catch (e) {
      debugPrint('Eski mesajlar yüklenirken hata: $e');
    }
  }

  void _startMessageListener() {
    // WebSocket bağlantısı kurulacak
    // Gerçek zamanlı mesaj güncellemeleri için
  }

  void _showError(String message) {
    setState(() {
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

  Future<void> _sendMessage({String? text, File? image, String? audioPath}) async {
    if ((text?.isEmpty ?? true) && image == null && audioPath == null) return;

    setState(() => _isSending = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('http://localhost:8080/v1/api/conversations/${widget.conversationId}/messages'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $accessToken',
      });

      if (text != null) {
        request.fields['text'] = text;
      }

      if (image != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'image',
            image.path,
          ),
        );
      }

      if (audioPath != null) {
        request.files.add(
          await http.MultipartFile.fromPath(
            'audio',
            audioPath,
          ),
        );
      }

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final newMessage = json.decode(responseData)['message'];
        setState(() {
          _messages.add(Map<String, dynamic>.from(newMessage));
          _messageController.clear();
          _selectedImage = null;
          _recordingPath = null;
        });
        _scrollToBottom();
      } else {
        throw Exception('Mesaj gönderilemedi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj gönderilemedi'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
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
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await http.delete(
        Uri.parse('http://localhost:8080/v1/api/conversations/${widget.conversationId}/messages/$messageId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _messages.removeWhere((m) => m['id'] == messageId);
        });
      } else {
        throw Exception('Mesaj silinemedi');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mesaj silinemedi'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        border: Border(
          top: BorderSide(
            color: Colors.grey.withOpacity(0.1),
          ),
        ),
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
                  color: Colors.grey[800],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: Image.file(
                        _selectedImage!,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    ),
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.white),
                        onPressed: () {
                          setState(() {
                            _selectedImage = null;
                          });
                        },
                      ),
                    ),
                  ],
                ),
              ),
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.add_photo_alternate, color: Colors.white),
                  onPressed: _pickImage,
                ),
                IconButton(
                  icon: const Icon(Icons.camera_alt, color: Colors.white),
                  onPressed: _takePhoto,
                ),
                IconButton(
                  icon: Icon(
                    _showEmojiPicker ? Icons.keyboard : Icons.emoji_emotions,
                    color: Colors.white,
                  ),
                  onPressed: () {
                    setState(() {
                      _showEmojiPicker = !_showEmojiPicker;
                    });
                  },
                ),
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    style: const TextStyle(color: Colors.white),
                    maxLines: null,
                    decoration: InputDecoration(
                      hintText: 'Mesaj yazın...',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      filled: true,
                      fillColor: Colors.grey[800],
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                    onChanged: (value) {
                      // Yazıyor durumunu API'ye bildir
                    },
                  ),
                ),
                IconButton(
                  icon: _isSending
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send, color: Colors.white),
                  onPressed: _isSending
                      ? null
                      : () => _sendMessage(text: _messageController.text),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessage(Map<String, dynamic> message) {
    final bool isMe = message['senderId'] == widget.userId;
    final DateTime messageTime = DateTime.parse(message['createdAt']);
    final bool hasImage = message['imageUrl'] != null;
    final bool hasAudio = message['audioUrl'] != null;

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.only(
          left: isMe ? 50 : 8,
          right: isMe ? 8 : 50,
          top: 4,
          bottom: 4,
        ),
        decoration: BoxDecoration(
          color: isMe ? Colors.blue : Colors.grey[800],
          borderRadius: BorderRadius.circular(16),
        ),
        child: InkWell(
          onLongPress: isMe ? () => _showMessageOptions(message) : null,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (hasImage)
                  GestureDetector(
                    onTap: () => _showImageFullScreen(message['imageUrl']),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.network(
                        message['imageUrl'],
                        fit: BoxFit.cover,
                        width: 200,
                      ),
                    ),
                  ),
                if (hasAudio)
                  Container(
                    padding: const EdgeInsets.all(8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.play_arrow, color: Colors.white),
                          onPressed: () {
                            // Ses dosyasını oynat
                          },
                        ),
                        Container(
                          width: 100,
                          height: 2,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ],
                    ),
                  ),
                if (message['text'] != null)
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Text(
                      message['text'],
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 4, right: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        timeago.format(messageTime, locale: 'tr'),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message['isRead'] ?? false
                              ? Icons.done_all
                              : Icons.done,
                          size: 16,
                          color: message['isRead'] ?? false
                              ? Colors.blue
                              : Colors.grey[400],
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

  void _showMessageOptions(Map<String, dynamic> message) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey[900],
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.copy, color: Colors.white),
              title: const Text(
                'Kopyala',
                style: TextStyle(color: Colors.white),
              ),
              onTap: () {
                // Mesajı panoya kopyala
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Sil',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(message['id']);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(String messageId) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Mesajı Sil',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Bu mesajı silmek istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _deleteMessage(messageId);
            },
            child: const Text(
              'Sil',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  void _showImageFullScreen(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: Center(
            child: InteractiveViewer(
              child: Image.network(imageUrl),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: Row(
          children: [
            CircleAvatar(
              backgroundImage: widget.userAvatar != null
                  ? NetworkImage(widget.userAvatar!)
                  : null,
              child: widget.userAvatar == null
                  ? Text(
                      widget.username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.username,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                  ),
                ),
                if (_isTyping)
                  Text(
                    'yazıyor...',
                    style: TextStyle(
                      color: Colors.grey[400],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Sohbet ayarları menüsü
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        reverse: true,
                        padding: const EdgeInsets.all(8),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          return _buildMessage(_messages[_messages.length - 1 - index]);
                        },
                      ),
                if (_showScrollButton)
                  Positioned(
                    right: 16,
                    bottom: 16,
                    child: FloatingActionButton(
                      mini: true,
                      backgroundColor: Colors.blue,
                      child: const Icon(Icons.arrow_downward),
                      onPressed: _scrollToBottom,
                    ),
                  ),
              ],
            ),
          ),
          _buildMessageInput(),
        ],
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