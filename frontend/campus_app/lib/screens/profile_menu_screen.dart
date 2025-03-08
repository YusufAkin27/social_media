import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_media/enums/faculty.dart';
import 'package:social_media/enums/department.dart';
import 'package:social_media/enums/grade.dart';

class ProfileMenuScreen extends StatefulWidget {
  const ProfileMenuScreen({Key? key}) : super(key: key);

  @override
  _ProfileMenuScreenState createState() => _ProfileMenuScreenState();
}

class _ProfileMenuScreenState extends State<ProfileMenuScreen> {
  bool _isLoading = true;
  String _username = '';
  String _name = '';
  String _profilePhoto = '';
  String _userBio = '';
  int _followersCount = 0;
  int _followingCount = 0;
  int _postsCount = 0;
  int _storiesCount = 0;
  int _popularityScore = 0;
  String _faculty = '';
  String _department = '';
  String _grade = '';
  bool _isActive = false;
  bool _isPrivate = false;
  bool _hasError = false;
  String? _errorMessage;
  
  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _hasError = false;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      // Doğrudan HTTP isteği yapıyoruz
      final response = await http.get(
        Uri.parse('http://localhost:8080/v1/api/student/profile'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = json.decode(response.body);
        
        if (responseData['success'] == true && responseData['data'] != null) {
          final userData = responseData['data'];
          
          setState(() {
            _username = userData['username'] ?? '';
            _name = '${userData['firstName'] ?? ''} ${userData['lastName'] ?? ''}'.trim();
            _profilePhoto = userData['profilePhoto'] ?? '';
            _userBio = userData['biography'] ?? '';
            _followersCount = userData['follower']?.toInt() ?? 0;
            _followingCount = userData['following']?.toInt() ?? 0;
            _postsCount = userData['posts']?.toInt() ?? 0;
            _storiesCount = userData['stories']?.toInt() ?? 0;
            _popularityScore = userData['popularityScore']?.toInt() ?? 0;
            _faculty = _getFacultyString(userData['faculty']);
            _department = _getDepartmentString(userData['department']);
            _grade = _getGradeString(userData['grade']);
            _isActive = userData['isActive'] ?? false;
            _isPrivate = userData['isPrivate'] ?? false;
            _isLoading = false;
          });
        } else {
          setState(() {
            _hasError = true;
            _errorMessage = responseData['message'] ?? 'Veri alınamadı';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _hasError = true;
          _errorMessage = 'HTTP Hatası: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _hasError = true;
        _errorMessage = 'Bağlantı hatası: $e';
        _isLoading = false;
      });
    }
  }

  // Enum değerlerini displayName özelliğini kullanarak string'e çevirme
  String _getFacultyString(dynamic facultyValue) {
    if (facultyValue == null) return '';
    
    try {
      // Enum index'ini integer olarak al
      int index = facultyValue is int ? facultyValue : 0;
      
      // Geçerli bir index mi kontrol et
      if (index < 0 || index >= Faculty.values.length) {
        return 'Bilinmeyen Fakülte';
      }
      
      // Enum değerinin displayName özelliğini döndür
      return Faculty.values[index].displayName;
    } catch (e) {
      print('Fakülte dönüştürme hatası: $e');
      return 'Bilinmeyen Fakülte';
    }
  }
  
  String _getDepartmentString(dynamic departmentValue) {
    if (departmentValue == null) return '';
    
    try {
      // Enum index'ini integer olarak al
      int index = departmentValue is int ? departmentValue : 0;
      
      // Geçerli bir index mi kontrol et
      if (index < 0 || index >= Department.values.length) {
        return 'Bilinmeyen Bölüm';
      }
      
      // Enum değerinin displayName özelliğini döndür
      return Department.values[index].displayName;
    } catch (e) {
      print('Bölüm dönüştürme hatası: $e');
      return 'Bilinmeyen Bölüm';
    }
  }
  
  String _getGradeString(dynamic gradeValue) {
    if (gradeValue == null) return '';
    
    try {
      // Enum index'ini integer olarak al
      int index = gradeValue is int ? gradeValue : 0;
      
      // Geçerli bir index mi kontrol et
      if (index < 0 || index >= Grade.values.length) {
        return 'Bilinmeyen Sınıf';
      }
      
      // Enum değerinin displayName özelliğini döndür
      return Grade.values[index].displayName;
    } catch (e) {
      print('Sınıf dönüştürme hatası: $e');
      return 'Bilinmeyen Sınıf';
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Colors.grey[900],
          title: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
          content: const Text(
            'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal', style: TextStyle(color: Colors.white60)),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                final prefs = await SharedPreferences.getInstance();
                await prefs.remove('accessToken');
                if (!mounted) return;
                Navigator.of(context).pushNamedAndRemoveUntil(
                  '/login',
                  (Route<dynamic> route) => false,
                );
              },
              child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Profil Menüsü', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? _buildLoadingIndicator()
          : _hasError
              ? _buildErrorWidget()
              : _buildProfileMenu(),
    );
  }

  Widget _buildLoadingIndicator() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const CircularProgressIndicator(color: Colors.white),
          const SizedBox(height: 16),
          Text(
            'Profil bilgileri yükleniyor...',
            style: TextStyle(color: Colors.white70),
          )
        ],
      ),
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
              _errorMessage ?? 'Profil bilgileri yüklenirken bir hata oluştu.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserProfile,
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

  Widget _buildProfileMenu() {
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profil başlık bölümü
            _buildProfileHeader(),
            const SizedBox(height: 24),
            
            // Profil Yönetimi Bölümü
            _buildSectionTitle('Profil Yönetimi'),
            const SizedBox(height: 8),
            _buildMenuCard([
              _buildMenuItem(
                'Profili Düzenle',
                Icons.edit,
                () => Navigator.pushNamed(context, '/edit-profile'),
              ),
              _buildMenuItem(
                'Takipçiler',
                Icons.people,
                () => Navigator.pushNamed(context, '/followers'),
              ),
              _buildMenuItem(
                'Takip Edilenler',
                Icons.people_outline,
                () => Navigator.pushNamed(context, '/following'),
              ),
            ]),
            
            const SizedBox(height: 20),
            
            // İçerik Bölümü
            _buildSectionTitle('İçerik'),
            const SizedBox(height: 8),
            _buildMenuCard([
              _buildMenuItem(
                'Kaydedilen Gönderiler',
                Icons.bookmark,
                () => Navigator.pushNamed(context, '/saved-posts'),
              ),
              _buildMenuItem(
                'Beğenilen Gönderiler',
                Icons.favorite,
                () => Navigator.pushNamed(context, '/liked-posts'),
              ),
              _buildMenuItem(
                'Beğenilen Hikayeler',
                Icons.favorite_border,
                () => Navigator.pushNamed(context, '/liked-stories'),
              ),
              _buildMenuItem(
                'Yorumlarım',
                Icons.comment,
                () => Navigator.pushNamed(context, '/my-comments'),
              ),
              _buildMenuItem(
                'Arşivlenen Gönderiler',
                Icons.archive,
                () => Navigator.pushNamed(context, '/archived-posts'),
              ),
              _buildMenuItem(
                'Arşivlenen Hikayeler',
                Icons.auto_stories,
                () => Navigator.pushNamed(context, '/archived-stories'),
              ),
            ]),
            
            const SizedBox(height: 20),
            
            // Ayarlar Bölümü
            _buildSectionTitle('Ayarlar'),
            const SizedBox(height: 8),
            _buildMenuCard([
              _buildMenuItem(
                'Genel Ayarlar',
                Icons.settings,
                () => Navigator.pushNamed(context, '/settings'),
              ),
              _buildMenuItem(
                'Şifre Değiştir',
                Icons.lock,
                () => Navigator.pushNamed(context, '/change-password'),
              ),
              _buildMenuItem(
                'İki Faktörlü Doğrulama',
                Icons.security,
                () => Navigator.pushNamed(context, '/two-factor-auth'),
              ),
            ]),
            
            const SizedBox(height: 40),
            
            // Çıkış Yap Butonu
            Center(
              child: ElevatedButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Çıkış Yap', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red[800],
                  minimumSize: const Size(200, 45),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          // Profil fotoğrafı
          Stack(
            alignment: Alignment.bottomRight,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(50),
                child: _profilePhoto.isNotEmpty
                    ? CachedNetworkImage(
                        imageUrl: _profilePhoto,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Shimmer.fromColors(
                          baseColor: Colors.grey[800]!,
                          highlightColor: Colors.grey[700]!,
                          child: Container(
                            width: 100,
                            height: 100,
                            color: Colors.grey[800],
                          ),
                        ),
                        errorWidget: (context, url, error) => Container(
                          width: 100,
                          height: 100,
                          color: Colors.grey[800],
                          child: const Icon(Icons.person, color: Colors.white, size: 50),
                        ),
                      )
                    : Container(
                        width: 100,
                        height: 100,
                        color: Colors.grey[800],
                        child: const Icon(Icons.person, color: Colors.white, size: 50),
                      ),
              ),
              // Aktif/Çevrimiçi durumu göstergesi
              if (_isActive)
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: Colors.green,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.grey[900]!, width: 3),
                  ),
                ),
              
              // Popülerlik rozeti
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: _getPopularityColor(_popularityScore),
                      width: 3,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: _getPopularityColor(_popularityScore).withOpacity(0.3),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    _getPopularityIcon(_popularityScore),
                    color: _getPopularityColor(_popularityScore),
                    size: 20,
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Kullanıcı adı ve isim
          Text(
            _name,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '@$_username',
                style: TextStyle(fontSize: 14, color: Colors.grey[400]),
              ),
              if (_isPrivate)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: Icon(Icons.lock, size: 14, color: Colors.grey[400]),
                ),
            ],
          ),
          
          if (_userBio.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              _userBio,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white70),
            ),
          ],
          
          const SizedBox(height: 16),
          
          // Fakülte, bölüm ve sınıf bilgileri
          if (_faculty.isNotEmpty || _department.isNotEmpty || _grade.isNotEmpty) ...[
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: [
                  if (_faculty.isNotEmpty)
                    _buildInfoItem(Icons.school, _faculty),
                  if (_department.isNotEmpty)
                    _buildInfoItem(Icons.business, _department),
                  if (_grade.isNotEmpty)
                    _buildInfoItem(Icons.grade, _grade),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          
          // Takipçi ve popülerlik bilgileri
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem('$_postsCount', 'Gönderi', Icons.grid_on),
              const SizedBox(width: 16),
              _buildStatItem('$_followersCount', 'Takipçi', Icons.people),
              const SizedBox(width: 16),
              _buildStatItem('$_followingCount', 'Takip', Icons.people_outline),
              const SizedBox(width: 16),
              _buildPopularityStatItem('$_popularityScore', 'Popülerlik', _getPopularityIcon(_popularityScore)),
            ],
          ),
          
          const SizedBox(height: 16),
          
          // Profil sayfasına git butonu
          OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/user-profile'),
            icon: const Icon(Icons.person, size: 18),
            label: const Text('Profil Sayfasına Git'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white70),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white70),
          const SizedBox(width: 6),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String count, String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (label == 'Takipçi') {
          Navigator.pushNamed(context, '/followers');
        } else if (label == 'Takip') {
          Navigator.pushNamed(context, '/following');
        } else if (label == 'Gönderi') {
          Navigator.pushNamed(context, '/user-profile');
        }
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _getIconColor(label), size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPopularityStatItem(String count, String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        _showPopularityInfoDialog();
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _getPopularityColor(_popularityScore).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _getPopularityColor(_popularityScore), size: 18),
          ),
          const SizedBox(height: 4),
          Text(
            count,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          Text(
            label,
            style: TextStyle(color: Colors.grey[400], fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showPopularityInfoDialog() {
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
              _getPopularityIcon(_popularityScore),
              color: _getPopularityColor(_popularityScore),
              size: 24,
            ),
            const SizedBox(width: 8),
            const Text(
              'Popülerlik Puanı',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Mevcut Puan: $_popularityScore',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Popülerlik puanınız etkileşimlerinize, paylaşımlarınıza ve aldığınız beğenilere göre hesaplanır.',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 8),
            _buildPopularityLevels(),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Tamam'),
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

  Color _getIconColor(String label) {
    switch (label) {
      case 'Takipçi':
        return Colors.blue;
      case 'Takip':
        return Colors.green;
      case 'Gönderi':
        return Colors.orange;
      case 'Popülerlik':
        return _getPopularityColor(_popularityScore);
      default:
        return Colors.white;
    }
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

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildMenuCard(List<Widget> items) {
    return Card(
      color: Colors.grey[900],
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: items,
      ),
    );
  }

  Widget _buildMenuItem(String title, IconData iconData, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        child: Row(
          children: [
            Icon(iconData, color: Colors.blue, size: 22),
            const SizedBox(width: 16),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
          ],
        ),
      ),
    );
  }
} 