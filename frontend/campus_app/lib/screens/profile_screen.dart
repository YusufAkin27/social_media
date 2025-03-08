import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:line_icons/line_icons.dart';

class ProfileScreen extends StatefulWidget {
  final String username;

  const ProfileScreen({
    Key? key,
    required this.username,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? userProfile;
  bool isLoading = true;
  bool isPrivate = false;
  bool isFollowing = false;

  @override
  void initState() {
    super.initState();
    _fetchUserProfile();
    _checkFollowStatus();
  }

  Future<void> _fetchUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/api/student/account-details/${widget.username}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          userProfile = data['data'];
          isPrivate = userProfile?['isPrivate'] ?? false;
          isFollowing = userProfile?['isFollow'] ?? false;
          isLoading = false;
        });
      }
    } catch (e) {
      print('Profil yüklenirken hata: $e');
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      if (isFollowing) {
        // Takipten çıkar
        final response = await http.delete(
          Uri.parse('http://localhost:8080/v1/api/follow-relations/following/${widget.username}'),
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            isFollowing = false;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Takipten çıkarıldı')),
          );
        }
      } else {
        // Takip et
        final response = await http.post(
          Uri.parse('http://localhost:8080/v1/api/friendsRequest/send/${widget.username}'),
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            isFollowing = true;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Takip ediliyor')),
          );
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('İşlem başarısız oldu')),
      );
    }
  }

  Future<void> _checkFollowStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/api/student/isFollow?username=${widget.username}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isFollowing = data['isFollow'] ?? false;
        });
      }
    } catch (e) {
      print('Takip durumu kontrol edilirken hata: $e');
    }
  }

  Widget _buildStatColumn(String label, int count) {
    return Column(
      children: [
        Text(
          count.toString(),
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: TextStyle(color: Colors.grey[400]),
        ),
      ],
    );
  }

  Widget _buildPopularityColumn(int score) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: Colors.grey[900],
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(15),
            ),
            title: Row(
              children: [
                Icon(
                  _getPopularityIcon(score),
                  color: _getPopularityColor(score),
                  size: 24,
                ),
                const SizedBox(width: 8),
                const Text(
                  'Popülerlik Seviyesi',
                  style: TextStyle(color: Colors.white),
                ),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${userProfile?['fullName'] ?? widget.username} kullanıcısının popülerlik puanı:',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Icon(
                      _getPopularityIcon(score),
                      color: _getPopularityColor(score),
                      size: 32,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      score.toString(),
                      style: TextStyle(
                        color: _getPopularityColor(score),
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '/ ${_getPopularityTitle(score)}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                const Text(
                  'Popülerlik Seviyeleri:',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildPopularityLevels(),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Kapat'),
              ),
            ],
          ),
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getPopularityColor(score).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              _getPopularityIcon(score),
              color: _getPopularityColor(score),
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            score.toString(),
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            'Popülerlik',
            style: TextStyle(color: Colors.grey[400]),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularityLevels() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildPopularityLevel('Yeni Üye', 0, 20, Colors.grey),
        _buildPopularityLevel('Aktif Üye', 21, 50, Colors.green),
        _buildPopularityLevel('Popüler Üye', 51, 100, Colors.blue),
        _buildPopularityLevel('Yıldız Üye', 101, 200, Colors.purple),
        _buildPopularityLevel('Elit Üye', 201, null, Colors.orange),
      ],
    );
  }

  Widget _buildPopularityLevel(String title, int min, int? max, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            _getPopularityIcon(min),
            color: color,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(color: color),
          ),
          const Spacer(),
          Text(
            max != null ? '$min-$max' : '$min+',
            style: TextStyle(color: color),
          ),
        ],
      ),
    );
  }

  IconData _getPopularityIcon(int score) {
    if (score >= 201) return Icons.star;
    if (score >= 101) return Icons.star_half;
    if (score >= 51) return Icons.trending_up;
    if (score >= 21) return Icons.favorite;
    return Icons.person;
  }

  Color _getPopularityColor(int score) {
    if (score >= 201) return Colors.orange;
    if (score >= 101) return Colors.purple;
    if (score >= 51) return Colors.blue;
    if (score >= 21) return Colors.green;
    return Colors.grey;
  }

  String _getPopularityTitle(int score) {
    if (score >= 201) return 'Elit Üye';
    if (score >= 101) return 'Yıldız Üye';
    if (score >= 51) return 'Popüler Üye';
    if (score >= 21) return 'Aktif Üye';
    return 'Yeni Üye';
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: Text('Profil'),
        ),
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        elevation: 0,
        title: Text(
          userProfile?['username'] ?? '',
          style: TextStyle(color: Colors.white),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.more_vert, color: Colors.white),
            onPressed: () {
              // Menü işlemleri
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil Başlığı
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundImage: NetworkImage(userProfile?['profilePhoto'] ?? ''),
                        backgroundColor: Colors.grey[800],
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: Colors.black,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: _getPopularityColor(userProfile?['popularityScore'] ?? 0),
                              width: 2,
                            ),
                          ),
                          child: Icon(
                            _getPopularityIcon(userProfile?['popularityScore'] ?? 0),
                            color: _getPopularityColor(userProfile?['popularityScore'] ?? 0),
                            size: 16,
                          ),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(width: 20),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _buildStatColumn('Gönderi', userProfile?['postCount'] ?? 0),
                        _buildStatColumn('Takipçi', userProfile?['followerCount'] ?? 0),
                        _buildStatColumn('Takip', userProfile?['followingCount'] ?? 0),
                        _buildPopularityColumn(userProfile?['popularityScore'] ?? 0),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Biyografi
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    userProfile?['fullName'] ?? '',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  if (userProfile?['bio'] != null)
                    Text(
                      userProfile!['bio'],
                      style: TextStyle(color: Colors.white70),
                    ),
                ],
              ),
            ),

            // Takip Et / Mesaj Gönder Butonu
            Padding(
              padding: EdgeInsets.all(16),
              child: Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _toggleFollow,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: isFollowing ? Colors.grey[800] : Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        isFollowing ? 'Takip Ediliyor' : 'Takip Et',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  if (isFollowing)
                    SizedBox(width: 8),
                  if (isFollowing)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Mesaj gönderme işlemi
                        },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(color: Colors.grey[800]!),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          'Mesaj Gönder',
                          style: TextStyle(color: Colors.white),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Ortak Arkadaşlar
            if ((userProfile?['commonFriends'] ?? []).isNotEmpty)
              Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ortak Arkadaşlar',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      children: (userProfile?['commonFriends'] as List)
                          .map((friend) => Chip(
                                label: Text(friend),
                                backgroundColor: Colors.grey[800],
                                labelStyle: TextStyle(color: Colors.white),
                              ))
                          .toList(),
                    ),
                  ],
                ),
              ),

            // Öne Çıkan Hikayeler
            if (!isPrivate || isFollowing)
              Container(
                height: 100,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: EdgeInsets.symmetric(horizontal: 16),
                  itemCount: (userProfile?['featuredStories'] ?? []).length,
                  itemBuilder: (context, index) {
                    final story = userProfile!['featuredStories'][index];
                    return Padding(
                      padding: EdgeInsets.only(right: 8),
                      child: Column(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundImage: NetworkImage(story['coverPhoto']),
                            backgroundColor: Colors.grey[800],
                          ),
                          SizedBox(height: 4),
                          Text(
                            story['title'] ?? '',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

            // Gönderiler
            if (!isPrivate || isFollowing)
              GridView.builder(
                shrinkWrap: true,
                physics: NeverScrollableScrollPhysics(),
                padding: EdgeInsets.all(1),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 1,
                  mainAxisSpacing: 1,
                ),
                itemCount: (userProfile?['posts'] ?? []).length,
                itemBuilder: (context, index) {
                  final post = userProfile!['posts'][index];
                  return Image.network(
                    post['content'][0],
                    fit: BoxFit.cover,
                  );
                },
              ),

            // Gizli Hesap Mesajı
            if (isPrivate && !isFollowing)
              Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lock,
                        size: 64,
                        color: Colors.grey[600],
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Bu hesap gizli',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Fotoğrafları ve videoları görmek için takip et',
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
