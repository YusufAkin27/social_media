import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_media/services/postService.dart';
import 'package:social_media/services/likeService.dart';
import 'package:social_media/models/post_dto.dart';
import 'package:social_media/enums/faculty.dart';
import 'package:social_media/enums/department.dart';
import 'package:social_media/enums/grade.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({Key? key}) : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> with SingleTickerProviderStateMixin {
  // Profil verileri için değişkenler
  Map<String, dynamic>? userProfile;
  List<PostDTO> userPosts = [];
  List<PostDTO> likedPosts = [];
  bool isLoading = true;
  bool isLoadingPosts = false;
  bool isLoadingLikedPosts = false;
  String error = '';
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;
  final PostService _postService = PostService();
  final LikeService _likeService = LikeService();
  int currentPage = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserProfile();
    
    _scrollController.addListener(() {
      if (_scrollController.offset > 200 && !_showAppBarTitle) {
        setState(() {
          _showAppBarTitle = true;
        });
      } else if (_scrollController.offset <= 200 && _showAppBarTitle) {
        setState(() {
          _showAppBarTitle = false;
        });
      }

      // Sonsuz scroll için
      if (_scrollController.position.pixels == _scrollController.position.maxScrollExtent) {
        _loadMorePosts();
      }
    });

    // Tab değişikliğini dinle
    _tabController.addListener(() {
      if (_tabController.index == 1) {
        _fetchLikedPosts();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      isLoading = true;
      error = '';
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      if (accessToken.isEmpty) {
        setState(() {
          error = 'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.';
          isLoading = false;
        });
        return;
      }

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
          setState(() {
            userProfile = responseData['data'];
            isLoading = false;
          });
          
          // Profil yüklendikten sonra gönderileri yükle
          _fetchUserPosts();
        } else {
          setState(() {
            error = responseData['message'] ?? 'Veri alınamadı';
            isLoading = false;
          });
        }
      } else {
        setState(() {
          error = 'HTTP Hatası: ${response.statusCode}';
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        error = 'Bağlantı hatası: $e';
        isLoading = false;
      });
    }
  }

  // Enum değerlerini displayName özelliğini kullanarak string'e çevirme
  String getFacultyString(dynamic facultyValue) {
    if (facultyValue == null) return 'Bilinmeyen Fakülte';
    
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
  
  String getDepartmentString(dynamic departmentValue) {
    if (departmentValue == null) return 'Bilinmeyen Bölüm';
    
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
  
  String getGradeString(dynamic gradeValue) {
    if (gradeValue == null) return 'Bilinmeyen Sınıf';
    
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

  Future<void> _fetchUserPosts() async {
    if (isLoadingPosts) return;

    setState(() {
      isLoadingPosts = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await _postService.getMyPosts(accessToken, currentPage);
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          if (currentPage == 0) {
            userPosts = response.data!;
          } else {
            userPosts.addAll(response.data!);
          }
          currentPage++;
          isLoadingPosts = false;
        });
      } else {
        print('Gönderiler yüklenirken hata: ${response.message}');
        setState(() {
          isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('Gönderiler yüklenirken hata: $e');
      setState(() {
        isLoadingPosts = false;
      });
    }
  }

  Future<void> _fetchLikedPosts() async {
    if (isLoadingLikedPosts) return;

    setState(() {
      isLoadingLikedPosts = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';
      
      final response = await _likeService.getUserLikedPosts(accessToken);
      
      if (response.isSuccess && response.data != null) {
        setState(() {
          likedPosts = response.data!;
          isLoadingLikedPosts = false;
        });
      } else {
        print('Beğenilen gönderiler yüklenirken hata: ${response.message}');
        setState(() {
          isLoadingLikedPosts = false;
        });
      }
    } catch (e) {
      print('Beğenilen gönderiler yüklenirken hata: $e');
      setState(() {
        isLoadingLikedPosts = false;
      });
    }
  }

  Future<void> _loadMorePosts() async {
    if (_tabController.index == 0) {
      await _fetchUserPosts();
    }
  }

  Future<void> _refreshProfile() async {
    currentPage = 0;
    await _fetchUserProfile();
  }

  void _navigateToPage(String route) {
    Navigator.pushNamed(context, route);
  }

  void _showOptionsMenu() {
    // Doğrudan profil menü sayfasına yönlendir
    Navigator.pushNamed(context, '/profile-menu');
  }

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return _buildLoadingScreen();
    }

    if (error.isNotEmpty && userProfile == null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: Colors.black,
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: Colors.white,
        backgroundColor: Colors.black,
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              backgroundColor: Colors.black,
              expandedHeight: 0,
              floating: true,
              pinned: true,
              title: _showAppBarTitle 
                  ? Text(userProfile?['username'] ?? '', style: const TextStyle(color: Colors.white))
                  : null,
              actions: [
                IconButton(
                  icon: const Icon(Icons.add_box_outlined, color: Colors.white),
                  onPressed: () => _navigateToPage('/create-post'),
                  tooltip: 'Yeni Gönderi Oluştur',
                ),
                IconButton(
                  icon: const Icon(Icons.menu, color: Colors.white),
                  onPressed: _showOptionsMenu,
                  tooltip: 'Menü',
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: _buildProfileHeader(),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                TabBar(
                  controller: _tabController,
                  indicatorColor: Colors.white,
                  indicatorWeight: 2,
                  labelColor: Colors.white,
                  unselectedLabelColor: Colors.white60,
                  tabs: const [
                    Tab(icon: Icon(Icons.grid_on)),
                    Tab(icon: Icon(Icons.favorite_border)),
                    Tab(icon: Icon(Icons.bookmark_border)),
                  ],
                ),
              ),
              pinned: true,
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsGrid(),
              _buildLikedPostsGrid(),
              _buildSavedPostsGrid(),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.indigoAccent,
        child: const Icon(Icons.camera_alt, color: Colors.white),
        onPressed: () => _navigateToPage('/create-story'),
        tooltip: 'Yeni Hikaye Oluştur',
      ),
    );
  }

  Widget _buildLoadingScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Profil', style: TextStyle(color: Colors.white)),
      ),
      body: Shimmer.fromColors(
        baseColor: Colors.grey[900]!,
        highlightColor: Colors.grey[800]!,
        child: ListView(
          children: [
            const SizedBox(height: 20),
            // Profil resmi placeholder
            Center(
              child: Container(
                width: 100,
                height: 100,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 20),
            // İsim placeholder
            Center(
              child: Container(
                width: 150,
                height: 20,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 10),
            // Bio placeholder
            Center(
              child: Container(
                width: 250,
                height: 15,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            // Buton placeholder
            Center(
              child: Container(
                width: 200,
                height: 40,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 30),
            // Grid placeholder
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                mainAxisSpacing: 2,
                crossAxisSpacing: 2,
              ),
              itemCount: 12,
              itemBuilder: (_, __) => Container(
                color: Colors.white,
                height: 100,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Profil', style: TextStyle(color: Colors.white)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 80,
              color: Colors.redAccent,
            ),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.white70,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.indigoAccent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              onPressed: _fetchUserProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.black,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Profil fotoğrafı
              Hero(
                tag: 'profile_photo_${userProfile?['userId']}',
                child: GestureDetector(
                  onTap: () {
                    if (userProfile != null && userProfile?['profilePhoto'] != null && userProfile?['profilePhoto'].isNotEmpty) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => _FullScreenPhoto(
                            photoUrl: userProfile!['profilePhoto'],
                            heroTag: 'profile_photo_${userProfile?['userId']}',
                          ),
                        ),
                      );
                    }
                  },
                  child: Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white.withOpacity(0.3),
                            width: 3,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: userProfile != null && 
                                 userProfile?['profilePhoto'] != null && 
                                 userProfile?['profilePhoto'].isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: userProfile!['profilePhoto'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[900],
                                    child: const Center(
                                      child: CircularProgressIndicator(
                                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[900],
                                    child: const Icon(Icons.person, color: Colors.white, size: 50),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[900],
                                  child: const Icon(Icons.person, color: Colors.white, size: 50),
                                ),
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
                              color: _getPopularityColor(userProfile?['popularityScore'] ?? 0),
                              width: 3,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: _getPopularityColor(userProfile?['popularityScore'] ?? 0).withOpacity(0.3),
                                blurRadius: 8,
                                spreadRadius: 1,
                              ),
                            ],
                          ),
                          child: Icon(
                            _getPopularityIcon(userProfile?['popularityScore'] ?? 0),
                            color: _getPopularityColor(userProfile?['popularityScore'] ?? 0),
                            size: 20,
                          ),
                        ),
                      ),
                      // Online durum göstergesi
                      if (userProfile?['isActive'] == true)
                        Positioned(
                          top: 5,
                          right: 5,
                          child: Container(
                            width: 16,
                            height: 16,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.black,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 20),
              // İstatistikler
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildStatColumn('${userProfile?['posts'] ?? 0}', 'Gönderi', Icons.grid_on),
                    _buildStatColumn('${userProfile?['follower'] ?? 0}', 'Takipçi', Icons.people),
                    _buildStatColumn('${userProfile?['following'] ?? 0}', 'Takip', Icons.person_add),
                    _buildPopularityColumn(userProfile?['popularityScore'] ?? 0),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Kullanıcı bilgileri
          if (userProfile != null) ...[
            Row(
              children: [
                Text(
                  '${userProfile!['firstName'] ?? ''} ${userProfile!['lastName'] ?? ''}'.trim(),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontSize: 20,
                  ),
                ),
                const SizedBox(width: 8),
                if (userProfile!['isPrivate'] == true)
                  const Icon(Icons.lock, color: Colors.white70, size: 16),
              ],
            ),
            Text(
              '@${userProfile!['username'] ?? ''}',
              style: TextStyle(
                color: Colors.grey[400],
                fontSize: 16,
              ),
            ),
            if (userProfile!['biography'] != null && userProfile!['biography'].isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  userProfile!['biography'],
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
              ),
            const SizedBox(height: 16),
            // Eğitim bilgileri kartı
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                ),
              ),
              child: Column(
                children: [
                  _buildInfoRow(Icons.school, 'Fakülte', getFacultyString(userProfile!['faculty'])),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.business, 'Bölüm', getDepartmentString(userProfile!['department'])),
                  const SizedBox(height: 8),
                  _buildInfoRow(Icons.grade, 'Sınıf', getGradeString(userProfile!['grade'])),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          // Aksiyon butonları
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _navigateToPage('/edit-profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Profili Düzenle',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: IconButton(
                  onPressed: () => _navigateToPage('/settings'),
                  icon: const Icon(Icons.settings, color: Colors.white),
                  tooltip: 'Ayarlar',
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Hikayeler
          _buildStoriesRow(),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatColumn(String count, String label, IconData icon) {
    return GestureDetector(
      onTap: () {
        if (label == 'Takipçi') {
          _navigateToPage('/followers');
        } else if (label == 'Takip') {
          _navigateToPage('/following');
        } else if (label == 'Gönderi') {
          _tabController.animateTo(0);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.white70, size: 20),
            const SizedBox(height: 4),
            Text(
              count,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(color: Colors.grey[400], fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 14,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.end,
          ),
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
                  'Mevcut Puan: $score',
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Popülerlik',
            style: TextStyle(color: Colors.grey[400], fontSize: 14),
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

  Widget _buildStoriesRow() {
    // Hikaye yoksa gösterme
    if ((userProfile?['stories'] ?? 0) <= 0) {
      return const SizedBox.shrink();
    }

    // Örnek olarak dummy hikaye verisi
    final List<Map<String, dynamic>> stories = [
      {'id': 1, 'thumbnail': userProfile?['profilePhoto'] ?? '', 'title': 'Kampüs'},
      {'id': 2, 'thumbnail': '', 'title': 'Arkadaşlar'},
      {'id': 3, 'thumbnail': '', 'title': 'Etkinlik'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Öne Çıkan Hikayeler',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 90,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: stories.length + 1, // +1 for add new story button
            itemBuilder: (context, index) {
              // Yeni hikaye ekleme butonu
              if (index == 0) {
                return Container(
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    children: [
                      GestureDetector(
                        onTap: () => _navigateToPage('/create-featured-story'),
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white30, width: 1),
                          ),
                          child: const Icon(Icons.add, color: Colors.white, size: 30),
                        ),
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Yeni',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
                      ),
                    ],
                  ),
                );
              }

              final story = stories[index - 1];
              return Container(
                margin: const EdgeInsets.only(right: 12),
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: () {
                        // Seçilen hikayeyi göster
                        _navigateToPage('/featured-story/${story['id']}');
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white30, width: 1),
                        ),
                        child: ClipOval(
                          child: story['thumbnail'].isNotEmpty
                              ? CachedNetworkImage(
                                  imageUrl: story['thumbnail'],
                                  fit: BoxFit.cover,
                                  placeholder: (context, url) => Container(
                                    color: Colors.grey[900],
                                    child: const Center(
                                      child: SizedBox(
                                        width: 20,
                                        height: 20,
                                        child: CircularProgressIndicator(
                                          valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                  ),
                                  errorWidget: (context, url, error) => Container(
                                    color: Colors.grey[900],
                                    child: const Icon(Icons.photo, color: Colors.white, size: 30),
                                  ),
                                )
                              : Container(
                                  color: Colors.grey[900],
                                  child: const Icon(Icons.photo, color: Colors.white, size: 30),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      story['title'],
                      style: const TextStyle(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostsGrid() {
    if (isLoadingPosts && userPosts.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (userPosts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.photo_library_outlined,
        title: 'Henüz gönderi yok',
        message: 'Paylaştığın gönderiler burada görünecek',
        buttonText: 'İlk Gönderini Paylaş',
        onPressed: () => _navigateToPage('/create-post'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: userPosts.length + (isLoadingPosts ? 1 : 0),
      itemBuilder: (context, index) {
        if (index == userPosts.length) {
          return const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          );
        }

        final post = userPosts[index];
        return GestureDetector(
          onTap: () => _navigateToPage('/post/${post.postId}'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: post.content.isNotEmpty ? post.content.first : post.profilePhoto,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.error, color: Colors.white54),
                ),
              ),
              if (post.content.length > 1)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.collections,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSavedPostsGrid() {
    // Bu kısımda kaydedilen gönderiler gösterilecek
    return _buildEmptyState(
      icon: Icons.bookmark_border,
      title: 'Henüz kaydedilen gönderi yok',
      message: 'Kaydettiğin gönderiler burada görünecek',
    );
  }

  Widget _buildLikedPostsGrid() {
    if (isLoadingLikedPosts) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (likedPosts.isEmpty) {
      return _buildEmptyState(
        icon: Icons.favorite_border,
        title: 'Henüz beğenilen gönderi yok',
        message: 'Beğendiğin gönderiler burada görünecek',
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(1),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 1,
        mainAxisSpacing: 1,
      ),
      itemCount: likedPosts.length,
      itemBuilder: (context, index) {
        final post = likedPosts[index];
        return GestureDetector(
          onTap: () => _navigateToPage('/post/${post.postId}'),
          child: Stack(
            fit: StackFit.expand,
            children: [
              CachedNetworkImage(
                imageUrl: post.content.isNotEmpty ? post.content.first : post.profilePhoto,
                fit: BoxFit.cover,
                placeholder: (context, url) => Container(
                  color: Colors.grey[900],
                  child: const Center(
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                    ),
                  ),
                ),
                errorWidget: (context, url, error) => Container(
                  color: Colors.grey[900],
                  child: const Icon(Icons.error, color: Colors.white54),
                ),
              ),
              if (post.content.length > 1)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.7),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: const Icon(
                      Icons.collections,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String message,
    String? buttonText,
    VoidCallback? onPressed,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 80,
              color: Colors.white38,
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: const TextStyle(
                fontSize: 16,
                color: Colors.white60,
              ),
              textAlign: TextAlign.center,
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.indigoAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: Text(buttonText),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// Profil fotoğrafını tam ekran göstermek için widget
class _FullScreenPhoto extends StatelessWidget {
  final String photoUrl;
  final String heroTag;

  const _FullScreenPhoto({
    required this.photoUrl,
    required this.heroTag,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: GestureDetector(
          onTap: () => Navigator.pop(context),
          child: Hero(
            tag: heroTag,
            child: CachedNetworkImage(
              imageUrl: photoUrl,
              fit: BoxFit.contain,
              placeholder: (context, url) => const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                ),
              ),
              errorWidget: (context, url, error) => const Icon(
                Icons.error,
                color: Colors.red,
                size: 50,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabBar _tabBar;

  _SliverAppBarDelegate(this._tabBar);

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: Colors.black,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}
