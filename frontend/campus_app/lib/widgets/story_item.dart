import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

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

class _StoryItemState extends State<StoryItem> {
  Future<void> _likeStory(String storyId) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      final response = await http.post(
        Uri.parse('http://localhost:8080/v1/api/likes/story/$storyId'),
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
        Uri.parse('http://localhost:8080/v1/api/comments/story/$storyId'),
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
    
    // Eğer active değilse veya url boşsa, görüntüleme
    if (!isActive || photoUrl.isEmpty) {
      return Container(); // Boş container döndür
    }
    
    return GestureDetector(
      onTap: () => widget.onStoryTap?.call(),
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 8),
        child: Column(
          children: [
            Stack(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.purpleAccent, // Aktif hikaye rengi
                      width: 2,
                    ),
                  ),
                  child: Padding(
                    padding: EdgeInsets.all(2),
                    child: CircleAvatar(
                      backgroundImage: NetworkImage(profilePhoto.isNotEmpty 
                          ? profilePhoto 
                          : 'https://via.placeholder.com/60'),
                      radius: 28,
                    ),
                  ),
                ),
              ],
            ),
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
} 