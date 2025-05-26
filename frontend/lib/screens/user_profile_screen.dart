import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
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
import 'package:social_media/widgets/sidebar.dart';
import 'package:social_media/screens/followers_screen.dart';
import 'package:social_media/screens/following_screen.dart';
import 'package:line_icons/line_icons.dart';
import 'package:social_media/services/studentService.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:social_media/widgets/video_player_widget.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';

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
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.isDarkMode ? Colors.black : Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(
            color: themeProvider.isDarkMode ? Colors.white : Colors.black),
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
              errorWidget: (context, url, error) => Container(
                color: themeProvider.isDarkMode
                    ? Colors.grey[900]
                    : Colors.grey[200],
                child: Icon(CupertinoIcons.exclamationmark_triangle,
                    color:
                        themeProvider.isDarkMode ? Colors.red : Colors.red[600],
                    size: 50),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  final TabController _tabController;
  final bool isCurrentUser;
  final bool isDarkMode;

  _SliverAppBarDelegate(this._tabController,
      {this.isCurrentUser = true, required this.isDarkMode});

  @override
  double get minExtent => kToolbarHeight;
  @override
  double get maxExtent => kToolbarHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDarkMode
              ? [
                  Color(0xFF1A2639),
                  Color(0xFF1A2639).withOpacity(0.95),
                ]
              : [
                  Colors.white,
                  Colors.white.withOpacity(0.95),
                ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: TabBar(
        controller: _tabController,
        indicatorColor:
            isDarkMode ? Color(0xFF00A8CC) : Theme.of(context).primaryColor,
        indicatorWeight: 3,
        indicatorSize: TabBarIndicatorSize.label,
        labelColor:
            isDarkMode ? Color(0xFF00A8CC) : Theme.of(context).primaryColor,
        unselectedLabelColor: isDarkMode ? Colors.white60 : Colors.black54,
        labelStyle: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w500,
          fontSize: 14,
        ),
        tabs: isCurrentUser
            ? const [
                Tab(
                  icon: Icon(CupertinoIcons.square_grid_2x2_fill),
                  iconMargin: EdgeInsets.only(bottom: 4),
                  text: "Gönderi",
                ),
                Tab(
                  icon: Icon(CupertinoIcons.heart_fill),
                  iconMargin: EdgeInsets.only(bottom: 4),
                  text: "Beğeni",
                ),
                Tab(
                  icon: Icon(CupertinoIcons.bookmark_fill),
                  iconMargin: EdgeInsets.only(bottom: 4),
                  text: "Kayıt",
                ),
              ]
            : const [
                Tab(
                  icon: Icon(CupertinoIcons.square_grid_2x2_fill),
                  iconMargin: EdgeInsets.only(bottom: 4),
                  text: "Gönderi",
                ),
                Tab(
                  icon: Icon(CupertinoIcons.person_2_fill),
                  iconMargin: EdgeInsets.only(bottom: 4),
                  text: "Takipçi",
                ),
                Tab(
                  icon: Icon(CupertinoIcons.person_fill),
                  iconMargin: EdgeInsets.only(bottom: 4),
                  text: "Takip",
                ),
              ],
      ),
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return oldDelegate.isCurrentUser != isCurrentUser ||
        oldDelegate.isDarkMode != isDarkMode;
  }
}

class UserProfileScreen extends StatefulWidget {
  final String? username; // Optional username to view other profiles
  final int? userId; // Optional userId to directly use account-details API

  const UserProfileScreen({Key? key, this.username, this.userId})
      : super(key: key);

  @override
  _UserProfileScreenState createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen>
    with TickerProviderStateMixin {
  // Profil verileri için değişkenler
  Map<String, dynamic>? userProfile;
  List<PostDTO> userPosts = [];
  List<PostDTO> likedPosts = [];
  List<dynamic> followingList = [];
  List<dynamic> followersList = [];
  bool isLoading = true;
  bool isLoadingPosts = false;
  bool isLoadingLikedPosts = false;
  bool isLoadingFollowing = false;
  bool isLoadingFollowers = false;
  bool isCurrentUser = true;
  String error = '';
  late TabController _tabController;
  final ScrollController _scrollController = ScrollController();
  bool _showAppBarTitle = false;
  final PostService _postService = PostService();
  final LikeService _likeService = LikeService();
  int currentPage = 0;
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );

    // If username is provided, we're viewing someone else's profile
    isCurrentUser = widget.username == null;

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
      if (_scrollController.position.pixels ==
          _scrollController.position.maxScrollExtent) {
        _loadMorePosts();
      }
    });

    // Tab değişikliğini dinle
    _tabController.addListener(() {
      if (_tabController.index == 1 && isCurrentUser) {
        _fetchLikedPosts();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
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
      final username = widget.username;

      print('Fetching profile for username: $username');
      print('Access token available: ${accessToken.isNotEmpty}');

      if (accessToken.isEmpty) {
        setState(() {
          error = 'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.';
          isLoading = false;
        });
        return;
      }

      // Eğer oturum açmış kullanıcının kendi profili ise
      if (isCurrentUser) {
        final response = await http.get(
          Uri.parse('http://192.168.89.61:8080/v1/api/student/profile'),
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

            // Gönderilerini yükle
            _fetchUserPosts();
            return;
          }
        }

        // Kendi profilini alamadıysak hata göster
        setState(() {
          error = 'Profil bilgileri alınamadı.';
          isLoading = false;
        });
        _showErrorSnackbar(
            'Kendi profil bilgileriniz yüklenemedi. Lütfen tekrar giriş yapın.');
        return;
      }

      // Başka kullanıcının profili için - yeni account-details endpoint'ini kullan
      // İlk önce kullanıcı ID'sini almamız gerek
      int userId = -1;

      // Widget'ten userId parametresi geldiyse direkt kullan
      if (widget.userId != null && widget.userId! > 0) {
        userId = widget.userId!;
        print('Using provided userId: $userId');
      }
      // Kullanıcı adından ID bulmaya çalış (userId sağlanmadıysa)
      else {
        try {
          final userSearchResponse = await http.get(
            Uri.parse(
                'http://192.168.89.61:8080/v1/api/student/search?query=${Uri.encodeComponent(username ?? '')}'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          );

          if (userSearchResponse.statusCode == 200) {
            final searchData = json.decode(userSearchResponse.body);
            if (searchData['success'] == true && searchData['data'] != null) {
              final List<dynamic> users = searchData['data'];
              // Username'e göre filtrele
              final matchedUser = users.firstWhere(
                (user) => user['username'] == username,
                orElse: () => null,
              );

              if (matchedUser != null) {
                userId = matchedUser['userId'];
                print('Found user ID: $userId for username: $username');
              }
            }
          }
        } catch (e) {
          print('Error searching for user ID: $e');
        }
      }

      // Kullanıcı ID'si bulunamadıysa, takipçiler/takip edilenler listesinden bulmayı dene
      if (userId == -1) {
        try {
          final followingResponse = await http.get(
            Uri.parse(
                'http://192.168.89.61:8080/v1/api/follow-relations/following'),
            headers: {
              'Authorization': 'Bearer $accessToken',
              'Content-Type': 'application/json',
            },
          );

          if (followingResponse.statusCode == 200) {
            final followingData = json.decode(followingResponse.body);
            if (followingData['success'] == true &&
                followingData['data'] != null) {
              final List<dynamic> followingList = followingData['data'];
              final foundUser = followingList.firstWhere(
                (user) => user['username'] == username,
                orElse: () => null,
              );

              if (foundUser != null && foundUser['id'] != null) {
                userId = foundUser['id'];
                print('Found user ID from following: $userId');
              }
            }
          }

          // Takip edilenlerde bulunamadıysa takipçilerde ara
          if (userId == -1) {
            final followersResponse = await http.get(
              Uri.parse(
                  'http://192.168.89.61:8080/v1/api/follow-relations/followers'),
              headers: {
                'Authorization': 'Bearer $accessToken',
                'Content-Type': 'application/json',
              },
            );

            if (followersResponse.statusCode == 200) {
              final followersData = json.decode(followersResponse.body);
              if (followersData['success'] == true &&
                  followersData['data'] != null) {
                final List<dynamic> followersList = followersData['data'];
                final foundUser = followersList.firstWhere(
                  (user) => user['username'] == username,
                  orElse: () => null,
                );

                if (foundUser != null && foundUser['id'] != null) {
                  userId = foundUser['id'];
                  print('Found user ID from followers: $userId');
                }
              }
            }
          }
        } catch (e) {
          print('Error trying to find user ID from lists: $e');
        }
      }

      // Kullanıcı ID'si bulunduysa account-details endpoint'ini çağır
      if (userId != -1) {
        print(
            'Fetching user details using account-details API with userId: $userId');

        final detailsResponse = await http.get(
          Uri.parse(
              'http://192.168.89.61:8080/v1/api/student/account-details/$userId'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );

        print('Account details response: ${detailsResponse.statusCode}');

        if (detailsResponse.statusCode == 200) {
          final detailsData = json.decode(detailsResponse.body);

          if (detailsData['success'] == true && detailsData['data'] != null) {
            // Veri formatını dönüştür - account-details API farklı alan adları kullanıyor
            final accountDetails = detailsData['data'];

            // API'den gelen verileri UserProfileScreen'in beklediği formata dönüştür
            final Map<String, dynamic> profileData = {
              "id": accountDetails['userId'],
              "username": accountDetails['username'],
              "firstName": accountDetails['fullName']?.split(' ').first ?? '',
              "lastName":
                  accountDetails['fullName']?.split(' ').skip(1)?.join(' ') ??
                      '',
              "profilePhoto": accountDetails['profilePhoto'],
              "biography": accountDetails['bio'],
              "faculty": 0, // API bu bilgileri dönmüyor
              "department": 0,
              "grade": 0,
              "follower": accountDetails['followerCount'] ?? 0,
              "following": accountDetails['followingCount'] ?? 0,
              "posts": accountDetails['postCount'] ?? 0,
              "isActive": true,
              "isPrivate": accountDetails['private'] == true,
              "popularityScore": accountDetails['popularityScore'] ?? 0,
            };

            setState(() {
              userProfile = profileData;
              isLoading = false;

              // Eğer API'den gelen gönderi ve hikaye verileri varsa, bunları doğrudan ayarla
              if (accountDetails['posts'] != null) {
                userPosts = (accountDetails['posts'] as List)
                    .map((postData) => PostDTO.fromJson(postData))
                    .toList();
              }
            });

            print('Successfully loaded user profile from account-details');
            return;
          }
        }

        // API çağrısı başarısız oldu, hata detaylarını logla
        print('Failed to get account details: ${detailsResponse.statusCode}');
        try {
          print('Error response: ${detailsResponse.body}');
        } catch (_) {}
      }

      // Buraya kadar gelmişse, hiçbir yöntem başarılı olmadı
      // Alternatif yöntemleri dene ve basit profil oluştur
      print('Using fallback methods to create basic profile');

      // Basit profil oluştur
      if (username != null) {
        final fallbackProfile = {
          "id": 0,
          "username": username,
          "firstName": "Kullanıcı",
          "lastName": "",
          "email": null,
          "profilePhoto": null,
          "biography": "Kullanıcı profil bilgilerine erişilemiyor.",
          "faculty": 0,
          "department": 0,
          "grade": 0,
          "follower": 0,
          "following": 0,
          "posts": 0,
          "isActive": true,
          "isPrivate": false,
          "popularityScore": 0
        };

        setState(() {
          userProfile = fallbackProfile;
          isLoading = false;
          error = 'Profil bilgileri tam olarak yüklenemedi.';
        });

        _showErrorSnackbar(
            'Kullanıcı bilgileri kısmen gösteriliyor. Detaylı bilgilere erişim sağlanamadı.');
      } else {
        setState(() {
          error = 'Kullanıcı bilgisi bulunamadı.';
          isLoading = false;
        });
        _showErrorSnackbar('Kullanıcı bilgisi bulunamadı.');
      }
    } catch (e) {
      print('Critical profile loading error: $e');
      setState(() {
        error = 'Bağlantı hatası: $e';
        isLoading = false;
      });
      _showErrorSnackbar('Profil yüklenirken beklenmeyen bir hata oluştu.');
    }
  }

  void _showErrorSnackbar(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        duration: Duration(seconds: 5),
        action: SnackBarAction(
          label: 'Tamam',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
          },
          textColor: Colors.white,
        ),
      ),
    );
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

      if (isCurrentUser) {
        // Kendi gönderilerimizi yüklüyoruz
        final response =
            await _postService.getMyPosts(accessToken, currentPage);

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
      } else {
        // Başka bir kullanıcının gönderilerini yüklüyoruz
        final response = await http.get(
          Uri.parse(
              'http://192.168.89.61:8080/v1/api/post/${widget.username}/posts'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);

          if (responseData['success'] == true && responseData['data'] != null) {
            final List<dynamic> postsData = responseData['data'];
            final List<PostDTO> posts =
                postsData.map((post) => PostDTO.fromJson(post)).toList();

            setState(() {
              if (currentPage == 0) {
                userPosts = posts;
              } else {
                userPosts.addAll(posts);
              }
              currentPage++;
              isLoadingPosts = false;
            });
          } else {
            print('Gönderiler yüklenirken hata: ${responseData['message']}');
            setState(() {
              isLoadingPosts = false;
            });
          }
        } else {
          print('Gönderiler yüklenirken HTTP hatası: ${response.statusCode}');
          setState(() {
            isLoadingPosts = false;
          });
        }
      }
    } catch (e) {
      print('Gönderiler yüklenirken hata: $e');
      setState(() {
        isLoadingPosts = false;
      });
    }
  }

  Future<void> _fetchLikedPosts() async {
    if (isLoadingLikedPosts || !isCurrentUser) return;

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

  Future<void> _fetchFollowingList() async {
    if (isLoadingFollowing) return;

    setState(() {
      isLoadingFollowing = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/follow-relations/following/${widget.username}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            followingList = responseData['data'];
            isLoadingFollowing = false;
          });
          _animationController.reset();
          _animationController.forward();
        } else {
          print(
              'Takip edilen kullanıcılar yüklenirken hata: ${responseData['message']}');
          setState(() {
            isLoadingFollowing = false;
          });
        }
      } else {
        print(
            'Takip edilen kullanıcılar yüklenirken HTTP hatası: ${response.statusCode}');
        setState(() {
          isLoadingFollowing = false;
        });
      }
    } catch (e) {
      print('Takip edilen kullanıcılar yüklenirken hata: $e');
      setState(() {
        isLoadingFollowing = false;
      });
    }
  }

  Future<void> _fetchFollowersList() async {
    if (isLoadingFollowers) return;

    setState(() {
      isLoadingFollowers = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/follow-relations/followers/${widget.username}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true && responseData['data'] != null) {
          setState(() {
            followersList = responseData['data'];
            isLoadingFollowers = false;
          });
          _animationController.reset();
          _animationController.forward();
        } else {
          print('Takipçiler yüklenirken hata: ${responseData['message']}');
          setState(() {
            isLoadingFollowers = false;
          });
        }
      } else {
        print('Takipçiler yüklenirken HTTP hatası: ${response.statusCode}');
        setState(() {
          isLoadingFollowers = false;
        });
      }
    } catch (e) {
      print('Takipçiler yüklenirken hata: $e');
      setState(() {
        isLoadingFollowers = false;
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

  void _navigateToUserProfile(String username) {
    // Eğer zaten o kullanıcının profilindeyse bir şey yapma
    if (widget.username == username) return;

    // Aynı ekrana farklı kullanıcı adı ile git
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => UserProfileScreen(username: username),
      ),
    );
  }

  void _showOptionsMenu() {
    // Doğrudan profil menü sayfasına yönlendir
    Navigator.pushNamed(context, '/profile-menu');
  }

  Future<void> _followUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.post(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/follow-relations/follow/${widget.username}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // Refresh profile to update follower/following counts
          _refreshProfile();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${widget.username} kullanıcısını takip etmeye başladınız.'),
              backgroundColor: Color(0xFF00A8CC),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  responseData['message'] ?? 'Takip işlemi başarısız oldu.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('HTTP Hatası: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bağlantı hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unfollowUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.delete(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/follow-relations/unfollow/${widget.username}'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // Refresh profile to update follower/following counts
          _refreshProfile();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  '${widget.username} kullanıcısını takip etmeyi bıraktınız.'),
              backgroundColor: Color(0xFF00A8CC),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ??
                  'Takipten çıkma işlemi başarısız oldu.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('HTTP Hatası: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bağlantı hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Check if current user is following the profile user
  bool _isFollowing() {
    if (isCurrentUser || followersList.isEmpty) return false;

    // API actually returns 'true' if the followingList contains any user
    // The user can only be on the followers list if they are already following the profile
    // This needs to be properly validated from the API
    return true;
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
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3F6B88).withOpacity(0.8),
                    Color(0xFF264E5C).withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Icon(
                icon,
                size: 65,
                color: Colors.white.withOpacity(0.9),
              ),
            ),
            const SizedBox(height: 28),
            Text(
              title,
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                message,
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            if (buttonText != null && onPressed != null) ...[
              const SizedBox(height: 28),
              ElevatedButton.icon(
                onPressed: onPressed,
                icon: const Icon(CupertinoIcons.photo_on_rectangle),
                label: Text(buttonText),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0xFF00A8CC),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    if (isLoading) {
      return _buildLoadingScreen();
    }

    if (error.isNotEmpty && userProfile == null) {
      return _buildErrorScreen();
    }

    return Scaffold(
      backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        onRefresh: _refreshProfile,
        color: themeProvider.isDarkMode ? Colors.white : Colors.black,
        backgroundColor: themeProvider.isDarkMode
            ? Color(0xFF00A8CC)
            : Theme.of(context).primaryColor,
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) => [
            SliverAppBar(
              backgroundColor:
                  themeProvider.currentTheme.scaffoldBackgroundColor,
              expandedHeight: 0,
              floating: true,
              pinned: true,
              title: _showAppBarTitle
                  ? Text(
                      userProfile?['username'] ?? '',
                      style: TextStyle(
                        color: themeProvider
                            .currentTheme.textTheme.bodyLarge?.color,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
              actions: [
                if (isCurrentUser) ...[
                  IconButton(
                    icon: const Icon(CupertinoIcons.plus_square,
                        color: Colors.white),
                    onPressed: () => _navigateToPage('/create-post'),
                    tooltip: 'Yeni Gönderi Oluştur',
                  ),
                  IconButton(
                    icon: const Icon(CupertinoIcons.line_horizontal_3,
                        color: Colors.white),
                    onPressed: _showOptionsMenu,
                    tooltip: 'Menü',
                  ),
                ],
                if (!isCurrentUser) ...[
                  IconButton(
                    icon: const Icon(CupertinoIcons.ellipsis_vertical,
                        color: Colors.white),
                    onPressed: () {
                      // Show options for other user's profile
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: themeProvider.isDarkMode
                            ? Color(0xFF203A43)
                            : themeProvider
                                .currentTheme.scaffoldBackgroundColor,
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => Container(
                          padding: EdgeInsets.symmetric(vertical: 20),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              ListTile(
                                leading: Icon(
                                    CupertinoIcons.exclamationmark_shield,
                                    color: Colors.red),
                                title: Text('Kullanıcıyı Şikayet Et',
                                    style: TextStyle(
                                        color: themeProvider.currentTheme
                                            .textTheme.bodyLarge?.color)),
                                onTap: () {
                                  Navigator.pop(context);
                                  // Implement report user functionality
                                },
                              ),
                              ListTile(
                                leading: Icon(CupertinoIcons.eye_slash,
                                    color: Colors.grey),
                                title: Text('Kullanıcıyı Engelle',
                                    style: TextStyle(
                                        color: themeProvider.currentTheme
                                            .textTheme.bodyLarge?.color)),
                                onTap: () {
                                  Navigator.pop(context);
                                  // Implement block user functionality
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ],
            ),
            SliverToBoxAdapter(
              child: _buildProfileHeader(),
            ),
            SliverPersistentHeader(
              delegate: _SliverAppBarDelegate(
                _tabController,
                isCurrentUser: isCurrentUser,
                isDarkMode: themeProvider.isDarkMode,
              ),
              pinned: true,
            ),
          ],
          body: TabBarView(
            controller: _tabController,
            children: [
              _buildPostsGrid(),
              isCurrentUser ? _buildLikedPostsGrid() : _buildFollowersList(),
              isCurrentUser ? _buildSavedPostsGrid() : _buildFollowingList(),
            ],
          ),
        ),
      ),
      floatingActionButton: isCurrentUser
          ? Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: themeProvider.isDarkMode
                      ? [
                          Color(0xFF00A8CC),
                          Color(0xFF45C4B0),
                        ]
                      : [
                          Theme.of(context).primaryColor,
                          Theme.of(context).primaryColor.withBlue(
                                (Theme.of(context).primaryColor.blue * 0.8)
                                    .toInt(),
                              ),
                        ],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: themeProvider.isDarkMode
                        ? Color(0xFF00A8CC).withOpacity(0.4)
                        : Theme.of(context).primaryColor.withOpacity(0.4),
                    blurRadius: 10,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: FloatingActionButton(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Icon(CupertinoIcons.camera,
                    color:
                        themeProvider.isDarkMode ? Colors.white : Colors.white,
                    size: 26),
                onPressed: () => _navigateToPage('/create-story'),
                tooltip: 'Yeni Hikaye Oluştur',
              ),
            )
          : null,
      bottomNavigationBar: Sidebar(
        initialIndex: 4, // 4 is for Profile
        profilePhotoUrl:
            userProfile != null && userProfile!['profilePhoto'] != null
                ? userProfile!['profilePhoto']
                : '',
      ),
    );
  }

  Widget _buildLoadingScreen() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
        title: Text('Profil',
            style: TextStyle(
                color: themeProvider.currentTheme.textTheme.bodyLarge?.color)),
      ),
      body: Shimmer.fromColors(
        baseColor: Color(0xFF203A43),
        highlightColor: Color(0xFF2C5364),
        child: ListView(
          children: [
            const SizedBox(height: 20),
            // Profil resmi placeholder
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: const BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
              ),
            ),
            const SizedBox(height: 30),
            // İsim placeholder
            Center(
              child: Container(
                width: 170,
                height: 25,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 10),
            // Username placeholder
            Center(
              child: Container(
                width: 120,
                height: 20,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Bio placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 40),
              child: Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Stats placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 80,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Academic info placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 120,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
            ),
            const SizedBox(height: 20),
            // Button placeholder
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                width: double.infinity,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 30),
            // Grid placeholder
            Padding(
              padding: const EdgeInsets.all(4),
              child: GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 4,
                  crossAxisSpacing: 4,
                ),
                itemCount: 9,
                itemBuilder: (_, __) => Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  height: 100,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorScreen() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    return Scaffold(
      backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
        title: Text('Profil',
            style: TextStyle(
                color: themeProvider.currentTheme.textTheme.bodyLarge?.color)),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.redAccent.withOpacity(0.8),
                    Colors.red.withOpacity(0.8),
                  ],
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.red.withOpacity(0.3),
                    blurRadius: 15,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: const Icon(
                CupertinoIcons.exclamationmark_circle,
                size: 80,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Bir hata oluştu',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 16),
            Container(
              margin: EdgeInsets.symmetric(horizontal: 40),
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                error,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.white,
                      fontSize: 16,
                    ),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Color(0xFF00A8CC),
                foregroundColor: Colors.white,
                elevation: 4,
                padding:
                    const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: const Icon(CupertinoIcons.refresh),
              label: const Text(
                'Tekrar Dene',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              onPressed: _fetchUserProfile,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: themeProvider.isDarkMode
              ? [
                  Color(0xFF39547B),
                  Color(0xFF1A2639),
                ]
              : [
                  Theme.of(context).primaryColor.withOpacity(0.2),
                  themeProvider.currentTheme.scaffoldBackgroundColor,
                ],
          stops: const [0.0, 0.9],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Profile Cover Area with Curved Bottom
          Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              // Top gradient background with curve
              Container(
                height: 140,
                width: double.infinity,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3F6B88).withOpacity(0.6),
                      Color(0xFF264E5C).withOpacity(0.6),
                    ],
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(40),
                    bottomRight: Radius.circular(40),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.3),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                  ],
                ),
              ),

              // Profile photo positioned to overlap the curve
              Positioned(
                bottom: -60,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Color(0xFF1A2639),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.4),
                        blurRadius: 15,
                        spreadRadius: 2,
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: 'profile_photo_${userProfile?['userId']}',
                    child: GestureDetector(
                      onTap: () {
                        if (userProfile != null &&
                            userProfile?['profilePhoto'] != null &&
                            userProfile?['profilePhoto'].isNotEmpty) {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => _FullScreenPhoto(
                                photoUrl: userProfile!['profilePhoto'],
                                heroTag:
                                    'profile_photo_${userProfile?['userId']}',
                              ),
                            ),
                          );
                        }
                      },
                      child: Stack(
                        children: [
                          ClipOval(
                            child: Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 3,
                                ),
                              ),
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
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                    Colors.white54),
                                          ),
                                        ),
                                      ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                        color: Colors.grey[900],
                                        child: const Icon(
                                            CupertinoIcons
                                                .exclamationmark_triangle,
                                            color: Colors.white54),
                                      ),
                                    )
                                  : Container(
                                      color: Colors.grey[900],
                                      child: const Icon(
                                          CupertinoIcons
                                              .exclamationmark_triangle,
                                          color: Colors.white54),
                                    ),
                            ),
                          ),
                          // Online status indicator
                          if (userProfile?['isActive'] == true)
                            Positioned(
                              top: 10,
                              right: 10,
                              child: Container(
                                width: 18,
                                height: 18,
                                decoration: BoxDecoration(
                                  color: Color(0xFF9DDE70),
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Color(0xFF1A2639),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF9DDE70).withOpacity(0.3),
                                      blurRadius: 8,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Popularity badge
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Color(0xFF1A2639),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _getPopularityColor(
                                      userProfile?['popularityScore'] ?? 0),
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: _getPopularityColor(
                                            userProfile?['popularityScore'] ??
                                                0)
                                        .withOpacity(0.3),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              child: Icon(
                                _getPopularityIcon(
                                    userProfile?['popularityScore'] ?? 0),
                                color: _getPopularityColor(
                                    userProfile?['popularityScore'] ?? 0),
                                size: 18,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),

          // Space for profile photo overlap
          const SizedBox(height: 70),

          // Profile Info Section
          _buildUserInfoSection(isSmallScreen),
        ],
      ),
    );
  }

  Widget _buildUserInfoSection(bool isSmallScreen) {
    if (userProfile == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Name & Username
          Center(
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Flexible(
                      child: Text(
                        '${userProfile!['firstName'] ?? ''} ${userProfile!['lastName'] ?? ''}'
                            .trim(),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontSize: 24,
                          letterSpacing: 0.5,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (userProfile!['isPrivate'] == true)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: Icon(CupertinoIcons.lock_fill,
                            color: Colors.amber, size: 18),
                      ),
                  ],
                ),
                Text(
                  '@${userProfile!['username'] ?? ''}',
                  style: TextStyle(
                    color: Color(0xFF45C4B0),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 22),

          // Bio
          if (userProfile!['biography'] != null &&
              userProfile!['biography'].isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF3F6B88).withOpacity(0.6),
                    Color(0xFF264E5C).withOpacity(0.6),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: Colors.white.withOpacity(0.1),
                  width: 1,
                ),
              ),
              child: Text(
                userProfile!['biography'],
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  height: 1.4,
                ),
                textAlign: TextAlign.center,
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),

          const SizedBox(height: 24),

          // Stats
          _buildStatsBar(isSmallScreen),

          const SizedBox(height: 22),

          // Academic Info & Actions
          _buildAcademicInfoAndActions(),

          const SizedBox(height: 24),

          // Stories
          _buildStoriesRow(),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildStatsBar(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF3F6B88).withOpacity(0.5),
            Color(0xFF264E5C).withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Colors.white.withOpacity(0.1),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
            blurRadius: 10,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _buildStatsItem(userProfile?['posts'] ?? 0, 'Gönderi',
              CupertinoIcons.square_grid_2x2),
          _buildVerticalDivider(),
          _buildStatsItem(userProfile?['follower'] ?? 0, 'Takipçi',
              CupertinoIcons.person_2),
          _buildVerticalDivider(),
          _buildStatsItem(userProfile?['following'] ?? 0, 'Takip',
              CupertinoIcons.person_fill),
          _buildVerticalDivider(),
          _buildStatsItem(userProfile?['popularityScore'] ?? 0, 'Popülerlik',
              _getPopularityIcon(userProfile?['popularityScore'] ?? 0),
              iconColor:
                  _getPopularityColor(userProfile?['popularityScore'] ?? 0)),
        ],
      ),
    );
  }

  Widget _buildVerticalDivider() {
    return Container(
      height: 40,
      width: 1,
      color: Colors.white.withOpacity(0.2),
    );
  }

  Widget _buildStatsItem(int count, String label, IconData icon,
      {Color? iconColor}) {
    return InkWell(
      onTap: () async {
        if (label == 'Takipçi') {
          // Takipçiler sayfasına git
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FollowersScreen(
                username: widget.username ?? userProfile?['username'] ?? '',
              ),
            ),
          ).catchError((e) {
            print('Error navigating to FollowersScreen: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Takipçiler sayfasına erişilemedi: $e')),
            );
          });
        } else if (label == 'Takip') {
          // Takip edilenler sayfasına git
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => FollowingScreen(
                username: widget.username ?? userProfile?['username'] ?? '',
              ),
            ),
          ).catchError((e) {
            print('Error navigating to FollowingScreen: $e');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                  content: Text('Takip edilenler sayfasına erişilemedi: $e')),
            );
          });
        } else if (label == 'Gönderi') {
          _tabController.animateTo(0);
        } else if (label == 'Popülerlik') {
          _showPopularityInfoDialog(count);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: iconColor ?? Colors.white, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey[300],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAcademicInfoAndActions() {
    return Column(
      children: [
        // Academic Info Card
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3F6B88).withOpacity(0.6),
                Color(0xFF264E5C).withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              _buildInfoRow(CupertinoIcons.book_fill, 'Fakülte',
                  getFacultyString(userProfile!['faculty']), Colors.amber),
              const SizedBox(height: 12),
              _buildInfoRow(
                  CupertinoIcons.building_2_fill,
                  'Bölüm',
                  getDepartmentString(userProfile!['department']),
                  Colors.lightBlue),
              const SizedBox(height: 12),
              _buildInfoRow(CupertinoIcons.number_square_fill, 'Sınıf',
                  getGradeString(userProfile!['grade']), Colors.greenAccent),
            ],
          ),
        ),

        const SizedBox(height: 20),

        // Action Buttons
        if (isCurrentUser) ...[
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _navigateToPage('/edit-profile'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFF00A8CC),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    shadowColor: Color(0xFF00A8CC).withOpacity(0.5),
                  ),
                  child: const Text(
                    'Profili Düzenle',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3F6B88),
                      Color(0xFF264E5C),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () => _navigateToPage('/settings'),
                  icon:
                      const Icon(CupertinoIcons.settings, color: Colors.white),
                  iconSize: 22,
                  padding: EdgeInsets.all(12),
                  tooltip: 'Ayarlar',
                ),
              ),
            ],
          ),
        ] else ...[
          // If not current user, show follow/message buttons
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _isFollowing() ? _unfollowUser : _followUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: followersList.isNotEmpty
                        ? Colors.grey[700]
                        : Color(0xFF00A8CC),
                    foregroundColor: Colors.white,
                    elevation: 4,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    shadowColor: followersList.isNotEmpty
                        ? Colors.grey.withOpacity(0.5)
                        : Color(0xFF00A8CC).withOpacity(0.5),
                  ),
                  child: Text(
                    followersList.isNotEmpty ? 'Takip Ediliyor' : 'Takip Et',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Color(0xFF3F6B88),
                      Color(0xFF264E5C),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 6,
                      spreadRadius: 1,
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () =>
                      _navigateToPage('/messages/${widget.username}'),
                  icon: const Icon(CupertinoIcons.chat_bubble_text,
                      color: Colors.white),
                  iconSize: 22,
                  padding: EdgeInsets.all(12),
                  tooltip: 'Mesaj Gönder',
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildInfoRow(
      IconData icon, String label, String value, Color iconColor) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[300],
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showPopularityInfoDialog(int score) {
    final screenSize = MediaQuery.of(context).size;
    final dialogWidth =
        screenSize.width * (screenSize.width < 360 ? 0.9 : 0.85);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Color(0xFF203A43),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _getPopularityColor(score).withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getPopularityIcon(score),
                color: _getPopularityColor(score),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Popülerlik Puanı',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SizedBox(
          width: dialogWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  color: _getPopularityColor(score).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _getPopularityColor(score).withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Mevcut Puan: ',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '$score',
                      style: TextStyle(
                        color: _getPopularityColor(score),
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Popülerlik puanınız etkileşimlerinize, paylaşımlarınıza ve aldığınız beğenilere göre hesaplanır.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              _buildPopularityLevels(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Color(0xFF00A8CC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Tamam',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
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
        _buildPopularityLevel('Aktif Üye', 21, 50, Color(0xFF9DDE70)),
        _buildPopularityLevel('Popüler Üye', 51, 100, Color(0xFF45C4B0)),
        _buildPopularityLevel('Yıldız Üye', 101, 200, Color(0xFFD55AC0)),
        _buildPopularityLevel('Elit Üye', 201, null, Color(0xFFFF9D3D)),
      ],
    );
  }

  Widget _buildPopularityLevel(String title, int min, int? max, Color color) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            _getPopularityIcon(min),
            color: color,
            size: 18,
          ),
          const SizedBox(width: 10),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
          const Spacer(),
          Container(
            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.2),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              max != null ? '$min-$max' : '$min+',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getPopularityIcon(int score) {
    if (score >= 201) return CupertinoIcons.star_fill;
    if (score >= 101) return CupertinoIcons.star_lefthalf_fill;
    if (score >= 51) return CupertinoIcons.graph_circle_fill;
    if (score >= 21) return CupertinoIcons.heart_fill;
    return CupertinoIcons.person_fill;
  }

  Color _getPopularityColor(int score) {
    if (score >= 201) return Color(0xFFFF9D3D); // Orange more vibrant
    if (score >= 101) return Color(0xFFD55AC0); // Purple more vibrant
    if (score >= 51) return Color(0xFF45C4B0); // Blue more vibrant
    if (score >= 21) return Color(0xFF9DDE70); // Green more vibrant
    return Colors.grey;
  }

  Widget _buildStoriesRow() {
    // Hikaye yoksa gösterme
    if ((userProfile?['stories'] ?? 0) <= 0) {
      return const SizedBox.shrink();
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 360;
    final storySize = isSmallScreen ? 60.0 : 70.0;

    // Örnek olarak dummy hikaye verisi
    final List<Map<String, dynamic>> stories = [
      {
        'id': 1,
        'thumbnail': userProfile?['profilePhoto'] ?? '',
        'title': 'Kampüs'
      },
      {'id': 2, 'thumbnail': '', 'title': 'Arkadaşlar'},
      {'id': 3, 'thumbnail': '', 'title': 'Etkinlik'},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3F6B88).withOpacity(0.6),
                Color(0xFF264E5C).withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    CupertinoIcons.sparkles,
                    color: Colors.amber,
                    size: 20,
                  ),
                  SizedBox(width: 8),
                  Text(
                    'Öne Çıkan Hikayeler',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      fontSize: 16,
                      letterSpacing: 0.5,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: storySize + 30, // Height based on story size + text
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: stories.length + 1, // +1 for add new story button
                  itemBuilder: (context, index) {
                    // Yeni hikaye ekleme butonu
                    if (index == 0) {
                      return Container(
                        margin: const EdgeInsets.only(right: 16),
                        child: Column(
                          children: [
                            GestureDetector(
                              onTap: () =>
                                  _navigateToPage('/create-featured-story'),
                              child: Container(
                                width: storySize,
                                height: storySize,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                    colors: [
                                      Color(0xFF00A8CC),
                                      Color(0xFF45C4B0),
                                    ],
                                  ),
                                  shape: BoxShape.circle,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFF00A8CC).withOpacity(0.3),
                                      blurRadius: 10,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                                child: const Icon(CupertinoIcons.add,
                                    color: Colors.white, size: 32),
                              ),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Yeni',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      );
                    }

                    final story = stories[index - 1];
                    final storyColor = index % 3 == 1
                        ? [Color(0xFF00A8CC), Color(0xFF45C4B0)]
                        : index % 3 == 2
                            ? [Color(0xFF4DC672), Color(0xFF9DDE70)]
                            : [Color(0xFF8850C8), Color(0xFFAA7BE9)];

                    return Container(
                      margin: const EdgeInsets.only(right: 16),
                      child: Column(
                        children: [
                          GestureDetector(
                            onTap: () {
                              // Seçilen hikayeyi göster
                              _navigateToPage('/featured-story/${story['id']}');
                            },
                            child: Container(
                              width: storySize,
                              height: storySize,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: LinearGradient(
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                  colors: storyColor,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: storyColor[0].withOpacity(0.3),
                                    blurRadius: 10,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                              padding: const EdgeInsets.all(3),
                              child: Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border:
                                      Border.all(color: Colors.white, width: 2),
                                ),
                                child: ClipOval(
                                  child: story['thumbnail'].isNotEmpty
                                      ? CachedNetworkImage(
                                          imageUrl: story['thumbnail'],
                                          fit: BoxFit.cover,
                                          placeholder: (context, url) =>
                                              Container(
                                            color: Colors.grey[900],
                                            child: const Center(
                                              child: SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  valueColor:
                                                      AlwaysStoppedAnimation<
                                                              Color>(
                                                          Colors.white54),
                                                  strokeWidth: 2,
                                                ),
                                              ),
                                            ),
                                          ),
                                          errorWidget: (context, url, error) =>
                                              Container(
                                            color: Colors.grey[900],
                                            child: const Icon(
                                                CupertinoIcons
                                                    .exclamationmark_triangle,
                                                color: Colors.white54),
                                          ),
                                        )
                                      : Container(
                                          color: Colors.grey[900],
                                          child: const Icon(
                                              CupertinoIcons.photo,
                                              color: Colors.white54),
                                        ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            story['title'],
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w500),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
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
        icon: CupertinoIcons.photo_on_rectangle,
        title: 'Henüz gönderi yok',
        message: 'Paylaştığın gönderiler burada görünecek',
        buttonText: 'İlk Gönderini Paylaş',
        onPressed: () => _navigateToPage('/create-post'),
      );
    }

    return Column(
      children: [
        // Tab seçimi için üst bilgi
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3F6B88).withOpacity(0.6),
                Color(0xFF264E5C).withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.square_grid_2x2_fill,
                color: Colors.lightBlue,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Gönderiler',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${userPosts.length} gönderi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid görünümü
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
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
              final bool hasMedia = post.content.isNotEmpty;
              final String mediaUrl = hasMedia ? post.content.first : '';
              final bool isVideo = hasMedia && _isVideoContent(mediaUrl);

              return GestureDetector(
                onTap: () {
                  // Show post details in a modal
                  _showPostDetails(post);
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        hasMedia
                            ? isVideo
                                ? _buildVideoThumbnail(mediaUrl)
                                : CachedNetworkImage(
                                    imageUrl: mediaUrl,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: Colors.grey[900],
                                      child: const Center(
                                        child: CircularProgressIndicator(
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                  Colors.white54),
                                          strokeWidth: 2,
                                        ),
                                      ),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: Colors.grey[900],
                                      child: const Icon(
                                          CupertinoIcons
                                              .exclamationmark_triangle,
                                          color: Colors.white54),
                                    ),
                                  )
                            : Container(
                                color: Colors.grey[900],
                                padding: const EdgeInsets.all(8),
                                child: Center(
                                  child: Text(
                                    post.description ?? '',
                                    style: const TextStyle(
                                      color: Colors.white70,
                                      fontSize: 12,
                                    ),
                                    maxLines: 4,
                                    textAlign: TextAlign.center,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),

                        // Video indicator
                        if (isVideo)
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  CupertinoIcons.play_fill,
                                  color: Colors.white,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),

                        // Post details overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(CupertinoIcons.heart_fill,
                                    color: Colors.red, size: 14),
                                const SizedBox(width: 4),
                                Text(
                                  '${post.like}',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const Spacer(),
                                if (post.content.length > 1)
                                  Container(
                                    padding: EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                        CupertinoIcons.rectangle_stack_fill,
                                        color: Colors.white,
                                        size: 12),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Check if content is a video
  bool _isVideoContent(String url) {
    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.avi') ||
        url.endsWith('.mkv') ||
        url.endsWith('.webm') ||
        url.endsWith('.m3u8') ||
        url.contains('video');
  }

  // Build video thumbnail with play icon
  Widget _buildVideoThumbnail(String videoUrl) {
    return Stack(
      fit: StackFit.expand,
      children: [
        CachedNetworkImage(
          imageUrl: videoUrl,
          fit: BoxFit.cover,
          placeholder: (context, url) => Container(
            color: Colors.grey[900],
            child: const Center(
              child: CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white54),
                strokeWidth: 2,
              ),
            ),
          ),
          errorWidget: (context, url, error) => Container(
            color: Colors.grey[900],
            child: const Icon(CupertinoIcons.video_camera_solid,
                color: Colors.white54),
          ),
        ),
      ],
    );
  }

  void _showPostDetails(PostDTO post) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.black,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with close button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Gönderi Detayları',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white24),

            // Post content
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // User info
                    ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundImage: post.profilePhoto != null &&
                                post.profilePhoto.isNotEmpty
                            ? NetworkImage(post.profilePhoto)
                            : null,
                        backgroundColor: Colors.grey[800],
                        child: post.profilePhoto == null ||
                                post.profilePhoto.isEmpty
                            ? const Icon(Icons.person, color: Colors.white54)
                            : null,
                      ),
                      title: Text(
                        '@${post.username ?? 'Kullanıcı'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      trailing: Text(
                        _formatTimeAgo(post.createdAt),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ),

                    // Media content
                    if (post.content.isNotEmpty)
                      Container(
                        height: 300,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: Colors.grey[900],
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _isVideoContent(post.content[0])
                            ? VideoPlayerWidget(
                                videoUrl: post.content[0],
                                autoPlay: true,
                                looping: true,
                                showControls: true,
                                aspectRatio: 16 / 9,
                                fit: BoxFit.contain,
                                isInFeed: false,
                              )
                            : CachedNetworkImage(
                                imageUrl: post.content[0],
                                fit: BoxFit.cover,
                                placeholder: (context, url) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                                errorWidget: (context, url, error) =>
                                    const Center(
                                  child:
                                      Icon(Icons.error, color: Colors.white54),
                                ),
                              ),
                      ),

                    // Description
                    if (post.description != null && post.description.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          post.description,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                      ),

                    // Stats
                    Container(
                      margin: const EdgeInsets.symmetric(vertical: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey[850],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildPostStatItem(
                            icon: CupertinoIcons.heart_fill,
                            value: post.like ?? 0,
                            label: 'Beğeni',
                            color: Colors.red[400]!,
                          ),
                          _buildPostStatItem(
                            icon: CupertinoIcons.chat_bubble_fill,
                            value: post.comment ?? 0,
                            label: 'Yorum',
                            color: Colors.blue[400]!,
                          ),
                        ],
                      ),
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

  Widget _buildPostStatItem({
    required IconData icon,
    required int value,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(height: 4),
        Text(
          value.toString(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[400],
            fontSize: 12,
          ),
        ),
      ],
    );
  }

  Widget _buildSavedPostsGrid() {
    // Bu kısımda kaydedilen gönderiler gösterilecek
    return Column(
      children: [
        // Tab seçimi için üst bilgi
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              const Text(
                'Kaydedilen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Text(
                '0 gönderi',
                style: TextStyle(
                  color: Colors.grey.shade400,
                  fontSize: 14,
                ),
              ),
            ],
          ),
        ),

        Expanded(
          child: _buildEmptyState(
            icon: CupertinoIcons.bookmark,
            title: 'Henüz kaydedilen gönderi yok',
            message: 'Kaydettiğin gönderiler burada görünecek',
          ),
        ),
      ],
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
        icon: CupertinoIcons.heart,
        title: 'Henüz beğenilen gönderi yok',
        message: 'Beğendiğin gönderiler burada görünecek',
      );
    }

    return Column(
      children: [
        // Tab seçimi için üst bilgi
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3F6B88).withOpacity(0.6),
                Color(0xFF264E5C).withOpacity(0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Icon(
                CupertinoIcons.heart_fill,
                color: Colors.redAccent,
                size: 18,
              ),
              SizedBox(width: 8),
              Text(
                'Beğenilen',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Spacer(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${likedPosts.length} gönderi',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),

        // Grid view
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.all(4),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 4,
              mainAxisSpacing: 4,
            ),
            itemCount: likedPosts.length,
            itemBuilder: (context, index) {
              final post = likedPosts[index];
              return GestureDetector(
                onTap: () => _showPostDetails(post),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 4,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: post.content.isNotEmpty
                              ? post.content.first
                              : post.profilePhoto,
                          fit: BoxFit.cover,
                          placeholder: (context, url) => Container(
                            color: Colors.grey[900],
                            child: const Center(
                              child: CircularProgressIndicator(
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.white54),
                                strokeWidth: 2,
                              ),
                            ),
                          ),
                          errorWidget: (context, url, error) => Container(
                            color: Colors.grey[900],
                            child: const Icon(
                                CupertinoIcons.exclamationmark_triangle,
                                color: Colors.white54),
                          ),
                        ),

                        // Heart icon overlay
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.all(5),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 1,
                              ),
                            ),
                            child: const Icon(
                              CupertinoIcons.heart_fill,
                              color: Colors.red,
                              size: 14,
                            ),
                          ),
                        ),

                        // Post details overlay
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 8),
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.black.withOpacity(0.8),
                                  Colors.transparent,
                                ],
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                CircleAvatar(
                                  radius: 8,
                                  backgroundImage: post.profilePhoto.isNotEmpty
                                      ? CachedNetworkImageProvider(
                                          post.profilePhoto)
                                      : null,
                                  backgroundColor: Colors.grey[800],
                                  child: post.profilePhoto.isEmpty
                                      ? const Icon(CupertinoIcons.person,
                                          size: 8, color: Colors.white)
                                      : null,
                                ),
                                const SizedBox(width: 5),
                                Expanded(
                                  child: Text(
                                    post.username,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (post.content.length > 1)
                                  Container(
                                    padding: EdgeInsets.all(3),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: Icon(
                                        CupertinoIcons.rectangle_stack_fill,
                                        color: Colors.white,
                                        size: 12),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFollowersList() {
    if (isLoadingFollowers) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (followersList.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.person_2,
        title: 'Henüz takipçi yok',
        message: 'Takip ettiğin kullanıcılar burada görünecek',
        buttonText: 'Takip Et',
        onPressed: () => _followUser,
      );
    }

    // Tüm takipçileri göstermek için takipçileri sayfasına yönlendirme butonu ekleyelim
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowersScreen(
                    username: widget.username ?? userProfile?['username'] ?? '',
                  ),
                ),
              ).catchError((e) {
                print('Error navigating to FollowersScreen: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content: Text('Takipçiler sayfasına erişilemedi: $e')),
                );
              });
            },
            icon: const Icon(CupertinoIcons.person_2_fill),
            label: Text('Tüm Takipçileri Görüntüle (${followersList.length})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00A8CC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: followersList.length > 5 ? 5 : followersList.length,
            itemBuilder: (context, index) {
              final user = followersList[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['profilePhoto'] != null
                      ? CachedNetworkImageProvider(user['profilePhoto'])
                      : null,
                  backgroundColor: Colors.grey[800],
                  child: user['profilePhoto'] == null
                      ? const Icon(CupertinoIcons.person,
                          size: 24, color: Colors.white)
                      : null,
                ),
                title: Text(
                  '@${user['username']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Takipçi',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.person_add, color: Colors.white),
                  onPressed: () => _followUserById(user['id']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFollowingList() {
    if (isLoadingFollowing) {
      return const Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
        ),
      );
    }

    if (followingList.isEmpty) {
      return _buildEmptyState(
        icon: CupertinoIcons.person_fill,
        title: 'Henüz takip edilen kullanıcı yok',
        message: 'Takip ettiğin kullanıcılar burada görünecek',
        buttonText: 'Takip Et',
        onPressed: () => _followUser,
      );
    }

    // Tüm takip edilenleri göstermek için takip edilenler sayfasına yönlendirme butonu ekleyelim
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowingScreen(
                    username: widget.username ?? userProfile?['username'] ?? '',
                  ),
                ),
              ).catchError((e) {
                print('Error navigating to FollowingScreen: $e');
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                      content:
                          Text('Takip edilenler sayfasına erişilemedi: $e')),
                );
              });
            },
            icon: const Icon(CupertinoIcons.person_fill),
            label: Text(
                'Tüm Takip Edilenleri Görüntüle (${followingList.length})'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0xFF00A8CC),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            itemCount: followingList.length > 5 ? 5 : followingList.length,
            itemBuilder: (context, index) {
              final user = followingList[index];
              return ListTile(
                leading: CircleAvatar(
                  backgroundImage: user['profilePhoto'] != null
                      ? CachedNetworkImageProvider(user['profilePhoto'])
                      : null,
                  backgroundColor: Colors.grey[800],
                  child: user['profilePhoto'] == null
                      ? const Icon(CupertinoIcons.person,
                          size: 24, color: Colors.white)
                      : null,
                ),
                title: Text(
                  '@${user['username']}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  'Takip',
                  style: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.person_remove, color: Colors.white),
                  onPressed: () => _unfollowUserById(user['id']),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  // Helper methods for follow/unfollow by ID
  Future<void> _followUserById(dynamic userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.post(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/follow-relations/follow/$userId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // Refresh profile to update follower/following counts
          _refreshProfile();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kullanıcıyı takip etmeye başladınız.'),
              backgroundColor: Color(0xFF00A8CC),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  responseData['message'] ?? 'Takip işlemi başarısız oldu.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('HTTP Hatası: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bağlantı hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _unfollowUserById(dynamic userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.delete(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/follow-relations/unfollow/$userId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);

        if (responseData['success'] == true) {
          // Refresh profile to update follower/following counts
          _refreshProfile();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Kullanıcıyı takip etmeyi bıraktınız.'),
              backgroundColor: Color(0xFF00A8CC),
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(responseData['message'] ??
                  'Takipten çıkma işlemi başarısız oldu.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('HTTP Hatası: ${response.statusCode}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Bağlantı hatası: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // Format time ago
  String _formatTimeAgo(DateTime? dateTime) {
    if (dateTime == null) return '';
    return timeago.format(dateTime, locale: 'tr');
  }
}
