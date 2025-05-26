import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:line_icons/line_icons.dart';

class StoryItem extends StatefulWidget {
  final Map<String, dynamic> story;
  final Function? onStoryTap;

  const StoryItem({
    Key? key,
    required this.story,
    this.onStoryTap,
  }) : super(key: key);

  @override
  _StoryItemState createState() => _StoryItemState();
}

class _StoryItemState extends State<StoryItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  bool _isLoading = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _animController.repeat(reverse: true);

    // Veri kontrolü
    _validateStoryData();
  }

  void _validateStoryData() {
    final String photoUrl = widget.story['photoUrl'] ?? '';
    if (photoUrl.isEmpty) {
      setState(() {
        _hasError = true;
      });
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _likeStory(String storyId) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      final response = await http.post(
        Uri.parse('http://192.168.89.61:8080/v1/api/likes/story/$storyId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Hikaye beğenildi')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Hikaye beğenilirken bir hata oluştu')),
      );
    }
  }

  Future<void> _addComment(String storyId, String comment) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      final response = await http.post(
        Uri.parse('http://192.168.89.61:8080/v1/api/comments/story/$storyId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
        body: {
          'content': comment,
        },
      );

      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Yorum eklendi')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Yorum eklenirken bir hata oluştu')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Hikaye verilerini kontrol et
    final String username = widget.story['username'] ?? '';
    final String profilePhoto = widget.story['profilePhoto'] ?? '';
    final String photoUrl = widget.story['photoUrl'] ?? '';
    final bool isActive = widget.story['isActive'] ?? false;

    // Eğer active değilse ve kullanıcı adı boşsa, görüntüleme
    if (!isActive && username.isEmpty) {
      return Container(); // Boş container döndür
    }

    return GestureDetector(
      onTap: () => _hasError ? null : widget.onStoryTap?.call(),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            _buildStoryAvatar(profilePhoto, photoUrl, isActive),
            SizedBox(height: 4),
            Text(
              username,
              style: TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w400,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStoryAvatar(
      String profilePhoto, String photoUrl, bool isActive) {
    // Hikaye var mı yok mu kontrolü
    final bool hasStory = photoUrl.isNotEmpty && isActive;
    final Color borderColor = hasStory ? Colors.purpleAccent : Colors.grey;

    return Stack(
      children: [
        // Ana avatar çerçevesi
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: _hasError ? Colors.grey : borderColor,
              width: 2,
            ),
            gradient: _hasError
                ? null
                : (hasStory
                    ? LinearGradient(
                        colors: [Colors.purple, Colors.pink, Colors.orange],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null),
          ),
          child: Padding(
            padding: EdgeInsets.all(2),
            child: CircleAvatar(
              backgroundColor: Colors.black,
              backgroundImage: _hasError
                  ? null
                  : CachedNetworkImageProvider(profilePhoto.isNotEmpty
                      ? profilePhoto
                      : 'https://via.placeholder.com/60'),
              child: _hasError
                  ? Icon(LineIcons.exclamationCircle,
                      color: Colors.red, size: 24)
                  : profilePhoto.isEmpty
                      ? Icon(LineIcons.user, color: Colors.white54, size: 24)
                      : null,
            ),
          ),
        ),

        // Hikaye durumu göstergesi
        if (_hasError)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Icon(
                Icons.error_outline,
                color: Colors.white,
                size: 12,
              ),
            ),
          )
        else if (!isActive)
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.grey,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Icon(
                Icons.hourglass_empty,
                color: Colors.white,
                size: 12,
              ),
            ),
          )
        else
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.black, width: 1.5),
              ),
              child: Icon(
                Icons.visibility,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),

        // Loading indicator
        if (_isLoading && !_hasError)
          Container(
            width: 60,
            height: 60,
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              strokeWidth: 2,
            ),
          ),
      ],
    );
  }
}
