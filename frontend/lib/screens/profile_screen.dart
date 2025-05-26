import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:line_icons/line_icons.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:video_player/video_player.dart';
import 'package:social_media/widgets/pod_video_player.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:social_media/theme/app_theme.dart';
import 'package:social_media/screens/followers_screen.dart';
import 'package:social_media/screens/following_screen.dart';

// Custom SliverPersistentHeaderDelegate implementation
class _MySliverPersistentHeaderDelegate extends SliverPersistentHeaderDelegate {
  final TabBar tabBar;
  final Color backgroundColor;

  _MySliverPersistentHeaderDelegate(this.tabBar,
      {required this.backgroundColor});

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        boxShadow: shrinkOffset > 0
            ? [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ]
            : null,
      ),
      child: tabBar,
    );
  }

  @override
  double get maxExtent => tabBar.preferredSize.height;

  @override
  double get minExtent => tabBar.preferredSize.height;

  @override
  bool shouldRebuild(covariant _MySliverPersistentHeaderDelegate oldDelegate) {
    return tabBar != oldDelegate.tabBar ||
        backgroundColor != oldDelegate.backgroundColor;
  }
}

// Grid pattern painter for the background when no cover photo is available
class GridPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double gridSize;

  GridPainter({
    required this.color,
    this.strokeWidth = 1.0,
    this.gridSize = 20.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth;

    // Draw vertical lines
    for (double i = 0; i <= size.width; i += gridSize) {
      canvas.drawLine(Offset(i, 0), Offset(i, size.height), paint);
    }

    // Draw horizontal lines
    for (double i = 0; i <= size.height; i += gridSize) {
      canvas.drawLine(Offset(0, i), Offset(size.width, i), paint);
    }
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => false;
}

class ProfileScreen extends StatefulWidget {
  final String username;
  final int? userId;

  const ProfileScreen({
    Key? key,
    required this.username,
    this.userId,
  }) : super(key: key);

  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen>
    with TickerProviderStateMixin {
  Map<String, dynamic>? userProfile;
  List<dynamic> userPosts = [];
  bool isLoading = true;
  bool isLoadingPosts = false;
  bool isPrivate = false;
  bool isFollowing = false;
  bool isLoadingFollow = false;
  String? errorMessage;

  // Controllers
  late TabController _tabController;
  late ScrollController _scrollController;
  late AnimationController _animationController;

  // Video player controllers
  VideoPlayerController? _videoController;

  // UI elements
  final BorderRadius _borderRadius = BorderRadius.circular(16);
  final List<String> _tabs = [
    'Gönderiler',
    'Medya',
    'Kaydedilenler',
    'Beğeniler'
  ];
  bool _isScrolledUnder = false;

  // Saved posts data
  List<dynamic> savedPosts = [];
  bool isLoadingSavedPosts = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    _scrollController = ScrollController();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _scrollController.addListener(_onScroll);

    print(
        'ProfileScreen initialized with username: ${widget.username}, userId: ${widget.userId}');
    _fetchUserProfile();
    _checkFollowStatus();
    // Make sure we call this method separately to fetch saved posts
    _fetchSavedPosts();

    // Add listener to tab controller to fetch saved posts when navigating to that tab
    _tabController.addListener(() {
      if (_tabController.index == 2 &&
          savedPosts.isEmpty &&
          !isLoadingSavedPosts) {
        print('Navigated to saved posts tab, fetching saved posts');
        _fetchSavedPosts();
      }
    });

    // Start animation
    _animationController.forward();
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _tabController.removeListener(() {});
    _tabController.dispose();
    _animationController.dispose();

    // Dispose video controllers
    if (_videoController != null) {
      _videoController!.dispose();
    }

    super.dispose();
  }

  void _onScroll() {
    // Check if we've scrolled enough to change the app bar behavior
    final isScrolledUnder = _scrollController.positions.isNotEmpty &&
        _scrollController.offset >
            180; // When profile header is scrolled out of view

    if (_isScrolledUnder != isScrolledUnder) {
      setState(() {
        _isScrolledUnder = isScrolledUnder;
      });
    }
  }

  Future<void> _fetchUserProfile() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      // Fetch user profile
      final String endpoint = widget.userId != null
          ? 'http://192.168.89.61:8080/v1/api/student/account-details/${widget.userId}'
          : 'http://192.168.89.61:8080/v1/api/student/account-details/${widget.username}';

      print('Fetching profile with endpoint: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('Profile data received: $data');

        if (data['success'] == true && data['data'] != null) {
          setState(() {
            userProfile = data['data'];
            isPrivate = userProfile?['private'] ?? false;
            isFollowing = userProfile?['isFollow'] ?? false;
            isLoading = false;
          });

          // Fakülte ve bölüm bilgilerini logla
          print('Profile loaded successfully for: ${userProfile?['username']}');
          print('Faculty: ${userProfile?['faculty']}');
          print('Department: ${userProfile?['department']}');
          print('Grade: ${userProfile?['grade']}');

          // Fetch posts if profile loaded successfully
          _fetchUserPosts();
        } else {
          setState(() {
            errorMessage = data['message'] ?? 'Profil bilgileri alınamadı';
            isLoading = false;
          });
          print('Error loading profile: ${data['message']}');
        }
      } else {
        setState(() {
          errorMessage = 'HTTP Error: ${response.statusCode}';
          isLoading = false;
        });
        print('HTTP Error: ${response.statusCode}');
      }
    } catch (e) {
      print('Error loading profile: $e');
      setState(() {
        errorMessage = 'Bağlantı hatası: $e';
        isLoading = false;
      });
    }
  }

  Future<void> _fetchUserPosts() async {
    if (isPrivate && !isFollowing) {
      // Don't fetch posts for private accounts that user doesn't follow
      return;
    }

    setState(() {
      isLoadingPosts = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      // Fetch user posts
      final String username = userProfile?['username'] ?? widget.username;
      final String endpoint =
          'http://192.168.89.61:8080/v1/api/follow-relations/following/$username/posts';

      print('Fetching posts with endpoint: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            userPosts = data['data'];
            isLoadingPosts = false;
          });
          print('Posts loaded successfully, count: ${userPosts.length}');
        } else {
          print('No posts or error: ${data['message']}');
          setState(() {
            isLoadingPosts = false;
          });
        }
      } else {
        print('HTTP Error fetching posts: ${response.statusCode}');
        setState(() {
          isLoadingPosts = false;
        });
      }
    } catch (e) {
      print('Error loading posts: $e');
      setState(() {
        isLoadingPosts = false;
      });
    }
  }

  Future<void> _fetchSavedPosts() async {
    print("Fetching saved posts...");
    setState(() {
      isLoadingSavedPosts = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      // Fetch saved posts
      final String endpoint = 'http://192.168.89.61:8080/v1/api/post/recorded';

      print('Fetching saved posts with endpoint: $endpoint');

      final response = await http.get(
        Uri.parse(endpoint),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      print('Saved posts response status code: ${response.statusCode}');
      if (response.statusCode == 200) {
        final responseBody = response.body;
        // Log a shorter version to avoid overwhelming the logs
        print('Saved posts response received, length: ${responseBody.length}');

        final data = jsonDecode(responseBody);
        if (data['success'] == true && data['data'] != null) {
          final posts = data['data'] as List;
          print('Saved posts count from API: ${posts.length}');

          // Parse and log information about each post
          for (int i = 0; i < posts.length; i++) {
            final post = posts[i];
            print(
                'Post $i: ID=${post['postId']}, User=${post['username']}, HasContent=${post['content'] != null && post['content'].isNotEmpty}');
          }

          setState(() {
            savedPosts = posts;
            isLoadingSavedPosts = false;
          });
          print('Saved posts loaded successfully, count: ${savedPosts.length}');
        } else {
          print('No saved posts or error: ${data['message']}');
          setState(() {
            savedPosts = [];
            isLoadingSavedPosts = false;
          });
        }
      } else {
        print('HTTP Error fetching saved posts: ${response.statusCode}');
        setState(() {
          savedPosts = [];
          isLoadingSavedPosts = false;
        });
      }
    } catch (e) {
      print('Error loading saved posts: $e');
      setState(() {
        savedPosts = [];
        isLoadingSavedPosts = false;
      });
    }
  }

  Future<void> _toggleFollow() async {
    if (isLoadingFollow) return;

    setState(() {
      isLoadingFollow = true;
    });

    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';
    final username = userProfile?['username'] ?? widget.username;

    try {
      if (isFollowing) {
        // Unfollow
        final response = await http.delete(
          Uri.parse(
              'http://192.168.89.61:8080/v1/api/follow-relations/following/$username'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            isFollowing = false;
            isLoadingFollow = false;
          });
          _showSnackBar('Takipten çıkarıldı', isError: false);
        } else {
          setState(() {
            isLoadingFollow = false;
          });
          _showSnackBar('İşlem başarısız oldu: ${response.statusCode}',
              isError: true);
        }
      } else {
        // Follow
        final response = await http.post(
          Uri.parse(
              'http://192.168.89.61:8080/v1/api/friendsRequest/send/$username'),
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        );

        if (response.statusCode == 200) {
          setState(() {
            isFollowing = true;
            isLoadingFollow = false;
          });
          _showSnackBar('Takip isteği gönderildi', isError: false);
        } else {
          setState(() {
            isLoadingFollow = false;
          });
          _showSnackBar('İşlem başarısız oldu: ${response.statusCode}',
              isError: true);
        }
      }
    } catch (e) {
      setState(() {
        isLoadingFollow = false;
      });
      _showSnackBar('Bağlantı hatası: $e', isError: true);
    }
  }

  Future<void> _checkFollowStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      // If userProfile is already loaded, we already have the follow status
      if (userProfile != null && userProfile!.containsKey('isFollow')) {
        setState(() {
          isFollowing = userProfile!['isFollow'] ?? false;
        });
        return;
      }

      // Otherwise check follow status separately
      final String username = widget.username;
      final response = await http.get(
        Uri.parse(
            'http://192.168.89.61:8080/v1/api/student/isFollow?username=$username'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          isFollowing = data['isFollow'] ?? false;
        });
      }
    } catch (e) {
      print('Error checking follow status: $e');
    }
  }

  void _showSnackBar(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        margin: const EdgeInsets.all(10),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final theme = themeProvider.currentTheme;

    if (isLoading) {
      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: theme.appBarTheme.elevation,
          title: Text('Profil', style: theme.textTheme.titleLarge),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: _buildShimmerLoading(),
      );
    }

    if (errorMessage != null) {
      bool is403Error = errorMessage!.contains('403');
      String displayError = is403Error
          ? 'Bu profili görüntülemek için izniniz yok. Yeni API kullanımı için kullanıcı ID gereklidir.'
          : errorMessage!;

      return Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: theme.appBarTheme.backgroundColor,
          elevation: theme.appBarTheme.elevation,
          title: Text('Profil', style: theme.textTheme.titleLarge),
          leading: IconButton(
            icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  is403Error
                      ? CupertinoIcons.exclamationmark_shield
                      : Icons.error_outline,
                  color: is403Error ? Colors.amber : theme.colorScheme.error,
                  size: 80,
                ),
                const SizedBox(height: 16),
                Text(
                  is403Error ? 'Erişim Hatası' : 'Hata',
                  style: GoogleFonts.poppins(
                    color: theme.textTheme.titleLarge?.color,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  displayError,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      color:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    if (is403Error && widget.userId == null) {
                      _showSnackBar(
                          "Kullanıcı ID olmadan profil görüntülenemez.",
                          isError: true);
                    } else {
                      _fetchUserProfile();
                    }
                  },
                  icon: const Icon(Icons.refresh),
                  label: const Text('Yeniden Dene'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 12),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: RefreshIndicator(
        color: theme.colorScheme.secondary,
        backgroundColor: theme.cardTheme.color,
        onRefresh: () async {
          await _fetchUserProfile();
          await _fetchUserPosts();
        },
        child: NestedScrollView(
          controller: _scrollController,
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              // App Bar
              SliverAppBar(
                expandedHeight: 260.0,
                floating: false,
                pinned: true,
                backgroundColor: _isScrolledUnder
                    ? theme.appBarTheme.backgroundColor?.withOpacity(0.9)
                    : Colors.transparent,
                elevation: _isScrolledUnder ? 2 : 0,
                automaticallyImplyLeading: false,
                leading: IconButton(
                  icon: Icon(Icons.arrow_back, color: theme.iconTheme.color),
                  onPressed: () => Navigator.pop(context),
                ),
                actions: [
                  IconButton(
                    icon: Icon(LineIcons.share, color: theme.iconTheme.color),
                    tooltip: 'Share Profile',
                    onPressed: () {
                      _showSnackBar('Profile sharing coming soon!',
                          isError: false);
                    },
                  ),
                  IconButton(
                    icon: Icon(Icons.more_vert, color: theme.iconTheme.color),
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        backgroundColor: theme.cardTheme.color,
                        shape: const RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.vertical(top: Radius.circular(20)),
                        ),
                        builder: (context) => _buildProfileOptionsSheet(),
                      );
                    },
                  ),
                ],
                title: _isScrolledUnder
                    ? Row(
                        children: [
                          CircleAvatar(
                            radius: 16,
                            backgroundImage:
                                userProfile?['profilePhoto'] != null &&
                                        userProfile!['profilePhoto'].isNotEmpty
                                    ? NetworkImage(userProfile!['profilePhoto'])
                                    : null,
                            backgroundColor: theme.colorScheme.surface,
                            child: userProfile?['profilePhoto'] == null ||
                                    userProfile!['profilePhoto'].isEmpty
                                ? Icon(Icons.person,
                                    color: theme.textTheme.bodyMedium?.color
                                        ?.withOpacity(0.5),
                                    size: 16)
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Text(
                            '@${userProfile?['username'] ?? widget.username}',
                            style: GoogleFonts.poppins(
                              color: theme.textTheme.titleLarge?.color,
                              fontWeight: FontWeight.w600,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      )
                    : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: _buildProfileHeader(),
                ),
              ),

              // Profile Info
              SliverToBoxAdapter(
                child: _buildProfileInfo().animate().fade(),
              ),

              // Tab Bar
              if (!isPrivate || isFollowing)
                SliverPersistentHeader(
                  delegate: _MySliverPersistentHeaderDelegate(
                    TabBar(
                      controller: _tabController,
                      tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
                      indicatorColor: theme.colorScheme.secondary,
                      indicatorWeight: 3,
                      indicatorSize: TabBarIndicatorSize.label,
                      labelColor: theme.colorScheme.secondary,
                      unselectedLabelColor:
                          theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
                      labelStyle: GoogleFonts.poppins(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    backgroundColor: theme.scaffoldBackgroundColor,
                  ),
                  pinned: true,
                ),
            ];
          },
          body: isPrivate && !isFollowing
              ? _buildPrivateAccountMessage()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    // Posts Tab
                    isLoadingPosts
                        ? _buildPostsLoadingShimmer()
                        : userPosts.isEmpty
                            ? _buildEmptyStateMessage(
                                icon: Icons.photo_library_outlined,
                                title: 'Henüz gönderi yok',
                                message: 'Gönderiler burada görünecek')
                            : _buildPostsGrid(),

                    // Media Tab
                    userPosts.any((post) =>
                            post['content'] != null &&
                            post['content'].isNotEmpty)
                        ? _buildMediaGallery()
                        : _buildEmptyStateMessage(
                            icon: LineIcons.photoVideo,
                            title: 'Medya bulunamadı',
                            message: 'Fotoğraf ve videolar burada görünecek'),

                    // Saved Posts Tab
                    Builder(builder: (context) {
                      print(
                          'Building Saved Posts Tab. isLoadingSavedPosts: $isLoadingSavedPosts, savedPosts.length: ${savedPosts.length}');
                      return isLoadingSavedPosts
                          ? _buildPostsLoadingShimmer()
                          : savedPosts.isEmpty
                              ? _buildEmptyStateMessage(
                                  icon: Icons.bookmark_border,
                                  title: 'Henüz kaydedilen gönderi yok',
                                  message:
                                      'Kaydettiğiniz gönderiler burada görünecek')
                              : _buildSavedPostsGrid();
                    }),

                    // Likes Tab
                    _buildEmptyStateMessage(
                        icon: LineIcons.heart,
                        title: 'Henüz beğeni yok',
                        message:
                            'Bu kullanıcının beğendiği gönderiler burada görünecek'),
                  ],
                ),
        ),
      ),
    );
  }

  Widget _buildShimmerLoading() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  shape: BoxShape.circle,
                ),
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                  duration: 1500.ms,
                  color: theme.cardTheme.color ?? Colors.grey[700]!),
              const SizedBox(width: 20),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    3,
                    (index) => Column(
                      children: [
                        Container(
                          width: 40,
                          height: 20,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          width: 60,
                          height: 16,
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surface,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(
              duration: 1500.ms,
              color: theme.cardTheme.color ?? Colors.grey[700]!),
          const SizedBox(height: 16),
          Container(
            width: 200,
            height: 20,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(
              duration: 1500.ms,
              color: theme.cardTheme.color ?? Colors.grey[700]!),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(
              duration: 1500.ms,
              color: theme.cardTheme.color ?? Colors.grey[700]!),
          const SizedBox(height: 4),
          Container(
            width: MediaQuery.of(context).size.width * 0.7,
            height: 16,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(4),
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(
              duration: 1500.ms,
              color: theme.cardTheme.color ?? Colors.grey[700]!),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
            ],
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(
              duration: 1500.ms,
              color: theme.cardTheme.color ?? Colors.grey[700]!),
          const SizedBox(height: 24),
          // Tab bar shimmer
          Container(
            height: 40,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
            ),
          ).animate(onPlay: (controller) => controller.repeat()).shimmer(
              duration: 1500.ms,
              color: theme.cardTheme.color ?? Colors.grey[700]!),
          const SizedBox(height: 16),
          // Grid placeholder
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: 6,
            itemBuilder: (context, index) {
              return Container(
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(8),
                ),
              ).animate(onPlay: (controller) => controller.repeat()).shimmer(
                  duration: 1500.ms,
                  color: theme.cardTheme.color ?? Colors.grey[700]!);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProfileOptionsSheet() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final _textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.block, color: Colors.white70),
              title: Text('Engelle', style: TextStyle(color: _textColor)),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Engelleme özelliği yakında aktif olacak',
                    isError: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.flag, color: Colors.white70),
              title: Text('Şikayet Et', style: TextStyle(color: _textColor)),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Şikayet özelliği yakında aktif olacak',
                    isError: false);
              },
            ),
            ListTile(
              leading: const Icon(Icons.visibility_off, color: Colors.white70),
              title: Text('Gizle', style: TextStyle(color: _textColor)),
              onTap: () {
                Navigator.pop(context);
                _showSnackBar('Profil gizlendi', isError: false);
              },
            ),
            Divider(color: _textColor.withOpacity(0.24)),
            ListTile(
              leading: const Icon(Icons.close, color: Colors.red),
              title: Text('Kapat', style: TextStyle(color: _textColor)),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Stack(
      clipBehavior: Clip.none,
      fit: StackFit.expand,
      children: [
        // Cover photo with gradient overlay
        ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withOpacity(0.1),
                Colors.black.withOpacity(0.7),
              ],
            ).createShader(rect);
          },
          blendMode: BlendMode.darken,
          child: Container(
            height: 220,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              image: userProfile?['coverPhoto'] != null &&
                      userProfile!['coverPhoto'].isNotEmpty
                  ? DecorationImage(
                      image: CachedNetworkImageProvider(
                          userProfile!['coverPhoto']),
                      fit: BoxFit.cover,
                    )
                  : null,
            ),
            // Create a subtle pattern if no cover photo
            child: userProfile?['coverPhoto'] == null ||
                    userProfile!['coverPhoto'].isEmpty
                ? CustomPaint(
                    painter: GridPainter(
                      color: theme.colorScheme.primary.withOpacity(0.1),
                      strokeWidth: 1,
                      gridSize: 20,
                    ),
                  )
                : null,
          ),
        ),

        // Profile information overlay
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.only(left: 20, right: 20, bottom: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Profile photo
                    Hero(
                      tag: 'profile-${widget.username}',
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: theme.scaffoldBackgroundColor,
                            width: 4,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.2),
                              blurRadius: 10,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                        child: CircleAvatar(
                          radius: 45,
                          backgroundColor: theme.colorScheme.surface,
                          child: userProfile?['profilePhoto'] != null &&
                                  userProfile!['profilePhoto'].isNotEmpty
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(45),
                                  child: CachedNetworkImage(
                                    imageUrl: userProfile!['profilePhoto'],
                                    width: 90,
                                    height: 90,
                                    fit: BoxFit.cover,
                                    placeholder: (context, url) => Container(
                                      color: theme.colorScheme.surface,
                                      child: const CircularProgressIndicator(
                                          strokeWidth: 2),
                                    ),
                                    errorWidget: (context, url, error) =>
                                        Container(
                                      color: theme.colorScheme.primary
                                          .withOpacity(0.2),
                                      child: Icon(
                                        Icons.person,
                                        color: theme.colorScheme.primary,
                                        size: 40,
                                      ),
                                    ),
                                  ),
                                )
                              : Icon(
                                  Icons.person,
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.8),
                                  size: 40,
                                ),
                        ),
                      ),
                    ),

                    const SizedBox(width: 16),

                    // User name & statistics
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Name & verification badge
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  userProfile?['fullName'] ?? widget.username,
                                  style: GoogleFonts.poppins(
                                    color: theme.textTheme.titleLarge?.color,
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    shadows: [
                                      Shadow(
                                        color: Colors.black.withOpacity(0.5),
                                        blurRadius: 5,
                                      ),
                                    ],
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (userProfile?['isVerified'] == true ||
                                  userProfile?['popularityScore'] >= 100)
                                Padding(
                                  padding: const EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.verified,
                                    color: theme.colorScheme.secondary,
                                    size: 20,
                                  ),
                                ),
                            ],
                          ),

                          // Username
                          Text(
                            '@${userProfile?['username'] ?? widget.username}',
                            style: TextStyle(
                              color: theme.textTheme.titleMedium?.color
                                  ?.withOpacity(0.8),
                              fontSize: 14,
                              shadows: [
                                Shadow(
                                  color: Colors.black.withOpacity(0.5),
                                  blurRadius: 3,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    ).animate(controller: _animationController).fade();
  }

  Widget _buildProfileInfo() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bio section
          if (userProfile?['bio'] != null && userProfile!['bio'].isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Text(
                userProfile!['bio'],
                style: TextStyle(
                  color: theme.textTheme.bodyLarge?.color,
                  fontSize: 14,
                  height: 1.4,
                ),
              ).animate(delay: 400.ms).fadeIn(duration: 500.ms),
            ),

          // Eğitim bilgileri
          if (userProfile?['faculty'] != null ||
              userProfile?['department'] != null ||
              userProfile?['grade'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          LineIcons.graduationCap,
                          color: theme.colorScheme.primary,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Eğitim Bilgileri',
                          style: TextStyle(
                            color: theme.textTheme.titleMedium?.color,
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (userProfile?['faculty'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LineIcons.university,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getFacultyName(userProfile!['faculty']),
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (userProfile?['department'] != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Icon(
                              LineIcons.bookOpen,
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.7),
                              size: 14,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _getDepartmentName(userProfile!['department']),
                                style: TextStyle(
                                  color: theme.textTheme.bodyMedium?.color
                                      ?.withOpacity(0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (userProfile?['grade'] != null)
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            LineIcons.school,
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                            size: 14,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            _getGradeName(userProfile!['grade']),
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color
                                  ?.withOpacity(0.9),
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),
            ).animate(delay: 500.ms).fadeIn(duration: 500.ms),

          // Location & join date
          if (userProfile?['location'] != null &&
                  userProfile!['location'].isNotEmpty ||
              userProfile?['createdAt'] != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Wrap(
                spacing: 16,
                runSpacing: 8,
                children: [
                  if (userProfile?['location'] != null &&
                      userProfile!['location'].isNotEmpty)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LineIcons.mapMarker,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          userProfile!['location'],
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                  if (userProfile?['createdAt'] != null)
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          LineIcons.calendar,
                          color: theme.textTheme.bodyMedium?.color
                              ?.withOpacity(0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Katılma: ${_formatDate(userProfile!['createdAt'])}',
                          style: TextStyle(
                            color: theme.textTheme.bodyMedium?.color
                                ?.withOpacity(0.7),
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),

          // Stats row (posts, followers, following, popularity)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: _borderRadius,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatCard('Gönderi', userProfile?['postCount'] ?? 0,
                      LineIcons.photoVideo),
                  _buildStatCard('Takipçi', userProfile?['followerCount'] ?? 0,
                      LineIcons.userFriends),
                  _buildStatCard('Takip', userProfile?['followingCount'] ?? 0,
                      LineIcons.userPlus),
                  _buildPopularityCard(userProfile?['popularityScore'] ?? 0),
                ],
              ),
            ).animate(delay: 300.ms).slideY(
                begin: 0.2,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutQuad),
          ),

          // Follow / Message buttons
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: isLoadingFollow ? null : _toggleFollow,
                    icon: Icon(
                      isFollowing ? LineIcons.check : LineIcons.userPlus,
                      size: 18,
                    ),
                    label: Text(
                      isFollowing ? 'Takip Ediliyor' : 'Takip Et',
                      style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: theme.colorScheme.onPrimary,
                      backgroundColor: isFollowing
                          ? theme.colorScheme.surface
                          : theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isFollowing
                            ? BorderSide(
                                color:
                                    theme.colorScheme.primary.withOpacity(0.5))
                            : BorderSide.none,
                      ),
                    ),
                  ),
                ),
                if (isFollowing) const SizedBox(width: 12),
                if (isFollowing)
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        _showSnackBar('Mesajlaşma yakında gelecek!',
                            isError: false);
                      },
                      icon: const Icon(LineIcons.facebookMessenger, size: 18),
                      label: Text(
                        'Mesaj',
                        style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        foregroundColor: theme.colorScheme.onSecondary,
                        backgroundColor: theme.colorScheme.secondary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            ).animate(delay: 500.ms).slideY(
                begin: 0.2,
                end: 0,
                duration: 500.ms,
                curve: Curves.easeOutQuad),
          ),
        ],
      ),
    );
  }

  // Fakülte adını döndüren yardımcı fonksiyon
  String _getFacultyName(String? facultyCode) {
    if (facultyCode == null) return 'Bilinmiyor';

    // Fakülte kodlarını insan tarafından okunabilir hale çevirme
    return facultyCode
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  // Bölüm adını döndüren yardımcı fonksiyon
  String _getDepartmentName(String? departmentCode) {
    if (departmentCode == null) return 'Bilinmiyor';

    // Bölüm kodlarını insan tarafından okunabilir hale çevirme
    return departmentCode
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }

  // Sınıf bilgisini döndüren yardımcı fonksiyon
  String _getGradeName(String? gradeCode) {
    if (gradeCode == null) return 'Bilinmiyor';

    switch (gradeCode) {
      case 'HAZIRLIK':
        return 'Hazırlık';
      case 'BIRINCI_SINIF':
        return '1. Sınıf';
      case 'IKINCI_SINIF':
        return '2. Sınıf';
      case 'UCUNCU_SINIF':
        return '3. Sınıf';
      case 'DORDUNCU_SINIF':
        return '4. Sınıf';
      case 'BESINCI_SINIF':
        return '5. Sınıf';
      case 'ALTINCI_SINIF':
        return '6. Sınıf';
      default:
        // Bilinmeyen durumlarda düzgün formatlayarak gösterme
        return gradeCode
            .replaceAll('_', ' ')
            .split(' ')
            .map((word) =>
                word[0].toUpperCase() + word.substring(1).toLowerCase())
            .join(' ');
    }
  }

  Widget _buildStatCard(String label, int count, IconData icon) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return InkWell(
      onTap: () {
        if (label == 'Takipçi' || label == 'Takip') {
          _showSnackBar('${label} listesi yakında gelecek!', isError: false);
        }
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          children: [
            Icon(
              icon,
              color: theme.colorScheme.primary.withOpacity(0.8),
              size: 18,
            ),
            const SizedBox(height: 4),
            Text(
              _formatCount(count),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.poppins(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPopularityCard(int score) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return InkWell(
      onTap: () {
        _showPopularityDialog(score);
      },
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(3),
              decoration: BoxDecoration(
                color: _getPopularityColor(score).withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                _getPopularityIcon(score),
                color: _getPopularityColor(score),
                size: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              score.toString(),
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: theme.textTheme.titleLarge?.color,
              ),
            ),
            Text(
              'Popülerlik',
              style: GoogleFonts.poppins(
                color: theme.textTheme.bodySmall?.color,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPopularityDialog(int score) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final _cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final _secondaryColor =
        isDarkMode ? const Color(0xFF00BCD4) : const Color(0xFF00BCD4);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: _cardColor,
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
            Text(
              'Popülerlik Puanı',
              style: GoogleFonts.poppins(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
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
            child: Text(
              'Kapat',
              style: TextStyle(color: _secondaryColor),
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

  String _formatCount(int count) {
    if (count >= 1000000) {
      return '${(count / 1000000).toStringAsFixed(1)}M';
    } else if (count >= 1000) {
      return '${(count / 1000).toStringAsFixed(1)}K';
    }
    return count.toString();
  }

  String _formatDate(dynamic dateString) {
    try {
      if (dateString == null) return 'Bilinmiyor';

      final DateTime date = dateString is String
          ? DateTime.parse(dateString)
          : DateTime.fromMillisecondsSinceEpoch(dateString);

      return DateFormat('MMMM yyyy').format(date);
    } catch (e) {
      return 'Bilinmiyor';
    }
  }

  String _getTimeAgo(dynamic timestamp) {
    try {
      if (timestamp == null) return '';

      final DateTime postTime = timestamp is String
          ? DateTime.parse(timestamp)
          : DateTime.fromMillisecondsSinceEpoch(timestamp);

      final Duration difference = DateTime.now().difference(postTime);

      if (difference.inDays > 365) {
        return '${(difference.inDays / 365).floor()}y';
      } else if (difference.inDays > 30) {
        return '${(difference.inDays / 30).floor()}ay';
      } else if (difference.inDays > 0) {
        return '${difference.inDays}g';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}s';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}d';
      } else {
        return 'şimdi';
      }
    } catch (e) {
      return '';
    }
  }

  // Popularity helpers
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

  // Media detection
  bool _isVideoFile(String url) {
    return url.endsWith('.mp4') ||
        url.endsWith('.mov') ||
        url.endsWith('.avi') ||
        url.endsWith('.mkv') ||
        url.endsWith('.webm');
  }

  Widget _buildPostsGrid() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final _surfaceColor =
        isDarkMode ? AppColors.surfaceColor : AppColors.lightSurfaceColor;
    final _cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final _accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;

    if (isLoadingSavedPosts) {
      return _buildPostsLoadingShimmer();
    }

    if (savedPosts.isEmpty) {
      return _buildEmptyStateMessage(
          icon: Icons.bookmark_border,
          title: 'Henüz kaydedilen gönderi yok',
          message: 'Kaydettiğiniz gönderiler burada görünecek');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: savedPosts.length,
      itemBuilder: (context, index) {
        final post = savedPosts[index];
        final bool hasMedia =
            post['content'] != null && post['content'].isNotEmpty;
        final String description = post['description'] ?? '';
        final bool hasLikes = post['like'] != null && post['like'] > 0;
        final bool hasComments = post['comment'] != null && post['comment'] > 0;
        final String timeAgo = _getTimeAgo(post['createdAt']);

        return GestureDetector(
          onTap: () {
            _showPostDetails(post);
          },
          child: Container(
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Post image
                Expanded(
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Post content
                      hasMedia
                          ? CachedNetworkImage(
                              imageUrl: post['content'][0],
                              fit: BoxFit.cover,
                              placeholder: (context, url) => Container(
                                color: _surfaceColor,
                                child: const Center(
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                ),
                              ),
                              errorWidget: (context, url, error) => Container(
                                color: _surfaceColor,
                                child: const Center(
                                  child: Icon(Icons.broken_image,
                                      color: Colors.white38, size: 30),
                                ),
                              ),
                            )
                          : Container(
                              padding: const EdgeInsets.all(16),
                              color: _cardColor,
                              alignment: Alignment.center,
                              child: Text(
                                description,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                ),
                                maxLines: 10,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                              ),
                            ),

                      // Video indicator
                      if (hasMedia && _isVideoFile(post['content'][0]))
                        Positioned.fill(
                          child: Center(
                            child: Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.5),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(
                                Icons.play_arrow,
                                color: Colors.white,
                                size: 24,
                              ),
                            ),
                          ),
                        ),

                      // Multiple media indicator
                      if (hasMedia && post['content'].length > 1)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.collections,
                                  color: Colors.white,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '${post['content'].length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Location indicator
                      if (post['location'] != null &&
                          post['location'].isNotEmpty)
                        Positioned(
                          bottom: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  LineIcons.mapMarker,
                                  color: Colors.white,
                                  size: 12,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  post['location'],
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ),

                      // Saved indicator
                      Positioned(
                        top: 8,
                        left: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: _accentColor.withOpacity(0.9),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.bookmark,
                            color: Colors.white,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Post footer
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Username
                      Text(
                        '@${post['username'] ?? 'Kullanıcı'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                      // Description
                      if (description.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            description,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),

                      const SizedBox(height: 6),

                      // Date & stats
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            timeAgo,
                            style: TextStyle(
                              color: Colors.grey[400],
                              fontSize: 10,
                            ),
                          ),
                          Row(
                            children: [
                              if (hasLikes)
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: Row(
                                    children: [
                                      Icon(
                                        LineIcons.heart,
                                        color: Colors.red[400],
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        post['like'].toString(),
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (hasComments)
                                Row(
                                  children: [
                                    Icon(
                                      LineIcons.comment,
                                      color: Colors.grey[400],
                                      size: 12,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      post['comment'].toString(),
                                      style: TextStyle(
                                        color: Colors.grey[400],
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ).animate(delay: (50 * index).ms).fade(duration: 400.ms).moveY(
            begin: 20, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
      },
    );
  }

  Widget _buildMediaGallery() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;
    final _surfaceColor =
        isDarkMode ? AppColors.surfaceColor : AppColors.lightSurfaceColor;
    final _cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;

    // Filter only posts with media
    final mediaPosts = userPosts
        .where((post) => post['content'] != null && post['content'].isNotEmpty)
        .toList();

    if (mediaPosts.isEmpty) {
      return _buildEmptyStateMessage(
          icon: LineIcons.photoVideo,
          title: 'Medya bulunamadı',
          message: 'Fotoğraf ve videolar burada görünecek');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(8),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 3,
        mainAxisSpacing: 3,
      ),
      itemCount: mediaPosts.length,
      itemBuilder: (context, index) {
        final post = mediaPosts[index];
        final mediaUrl = post['content'][0];
        final bool isVideo =
            _isVideoFile(mediaUrl) || post['mediaType'] == 'video';

        return InkWell(
          onTap: () => _showPostDetails(post),
          child: Container(
            decoration: BoxDecoration(
              color: _surfaceColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Media thumbnail
                CachedNetworkImage(
                  imageUrl: mediaUrl,
                  fit: BoxFit.cover,
                  placeholder: (context, url) => Container(
                    color: _cardColor,
                    child: const Center(
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (context, url, error) => Container(
                    color: _cardColor,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.broken_image, color: Colors.white38),
                          if (isVideo)
                            Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                'Video',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 10,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),

                // Video indicator
                if (isVideo)
                  Positioned.fill(
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.center,
                          colors: [
                            Colors.black.withOpacity(0.7),
                            Colors.transparent,
                          ],
                        ),
                      ),
                      child: Center(
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.6),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.play_arrow,
                            color: Colors.white,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),

                // Multiple media indicator
                if (post['content'].length > 1)
                  Positioned(
                    top: 4,
                    right: 4,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.collections,
                        color: Colors.white,
                        size: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        )
            .animate(delay: (30 * index).ms)
            .fade(duration: 300.ms)
            .scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
      },
    );
  }

  void _showPostDetails(Map<String, dynamic> post) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final _cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final _surfaceColor =
        isDarkMode ? AppColors.surfaceColor : AppColors.lightSurfaceColor;

    // Navigate to post details or show a modal with post details
    showModalBottomSheet(
      context: context,
      backgroundColor: _cardColor,
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
                  style: GoogleFonts.poppins(
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
                        backgroundImage: post['profilePhoto'] != null &&
                                post['profilePhoto'].isNotEmpty
                            ? NetworkImage(post['profilePhoto'])
                            : null,
                        backgroundColor: _surfaceColor,
                        child: post['profilePhoto'] == null ||
                                post['profilePhoto'].isEmpty
                            ? const Icon(Icons.person, color: Colors.white54)
                            : null,
                      ),
                      title: Text(
                        '@${post['username'] ?? 'Kullanıcı'}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: post['location'] != null &&
                              post['location'].isNotEmpty
                          ? Row(
                              children: [
                                const Icon(
                                  LineIcons.mapMarker,
                                  color: Colors.white70,
                                  size: 14,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  post['location'],
                                  style: const TextStyle(color: Colors.white70),
                                ),
                              ],
                            )
                          : null,
                      trailing: Text(
                        _getTimeAgo(post['createdAt']),
                        style: TextStyle(
                          color: Colors.grey[400],
                          fontSize: 12,
                        ),
                      ),
                    ),

                    // Media content
                    if (post['content'] != null && post['content'].isNotEmpty)
                      Container(
                        height: 300,
                        margin: const EdgeInsets.symmetric(vertical: 12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          color: _surfaceColor,
                        ),
                        clipBehavior: Clip.antiAlias,
                        child: _isVideoFile(post['content'][0])
                            ? Center(
                                child: Text('Video içeriği',
                                    style: TextStyle(color: Colors.white)))
                            : CachedNetworkImage(
                                imageUrl: post['content'][0],
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
                    if (post['description'] != null &&
                        post['description'].isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        child: Text(
                          post['description'],
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
                        color: _surfaceColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildStatItem(
                            icon: LineIcons.heart,
                            value: post['like'] ?? 0,
                            label: 'Beğeni',
                            color: Colors.red[400]!,
                          ),
                          _buildStatItem(
                            icon: LineIcons.comment,
                            value: post['comment'] ?? 0,
                            label: 'Yorum',
                            color: Colors.blue[400]!,
                          ),
                          _buildStatItem(
                            icon: LineIcons.bookmark,
                            value: 1,
                            label: 'Kaydedildi',
                            color: Colors.purple[400]!,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Actions
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildActionButton(
                    icon: LineIcons.alternateTrash,
                    label: 'Kaldır',
                    onPressed: () {
                      _unsavePost(post['postId']);
                      Navigator.pop(context);
                    },
                    color: Colors.red,
                  ),
                  _buildActionButton(
                    icon: LineIcons.share,
                    label: 'Paylaş',
                    onPressed: () {
                      Navigator.pop(context);
                      _showSnackBar('Paylaşım özelliği yakında eklenecek',
                          isError: false);
                    },
                    color: Colors.blue,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem({
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

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    required Color color,
  }) {
    return ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon, color: Colors.white, size: 16),
      label: Text(label),
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  Future<void> _unsavePost(String postId) async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken') ?? '';

    try {
      final response = await http.delete(
        Uri.parse('http://192.168.89.61:8080/v1/api/post/recorded/$postId'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        _showSnackBar('Gönderi kaydedilenlerden kaldırıldı', isError: false);
        // Refresh saved posts
        _fetchSavedPosts();
      } else {
        _showSnackBar('İşlem başarısız oldu: ${response.statusCode}',
            isError: true);
      }
    } catch (e) {
      _showSnackBar('Bağlantı hatası: $e', isError: true);
    }
  }

  Widget _buildPostsLoadingShimmer() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    final surfaceColor = theme.colorScheme.surface;
    final cardColor = theme.cardTheme.color ?? Colors.grey[700]!;

    return GridView.builder(
      shrinkWrap: true,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.8,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        return Container(
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image placeholder
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cardColor,
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
              ),

              // Content placeholder
              Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      height: 10,
                      decoration: BoxDecoration(
                        color: Colors.grey[800],
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          width: 40,
                          height: 8,
                          decoration: BoxDecoration(
                            color: Colors.grey[800],
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        Row(
                          children: [
                            Container(
                              width: 20,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              width: 20,
                              height: 8,
                              decoration: BoxDecoration(
                                color: Colors.grey[800],
                                borderRadius: BorderRadius.circular(4),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        )
            .animate(onPlay: (controller) => controller.repeat())
            .shimmer(duration: 1500.ms, color: Colors.grey[700]!);
      },
    );
  }

  Widget _buildSavedPostsGrid() {
    print('Building saved posts grid. Posts count: ${savedPosts.length}');

    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    final surfaceColor =
        isDarkMode ? AppColors.surfaceColor : AppColors.lightSurfaceColor;
    final cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;

    if (savedPosts.isEmpty) {
      print('No saved posts to display');
      return _buildEmptyStateMessage(
          icon: Icons.bookmark_border,
          title: 'Henüz kaydedilen gönderi yok',
          message: 'Kaydettiğiniz gönderiler burada görünecek');
    }

    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.8,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: savedPosts.length,
      itemBuilder: (context, index) {
        try {
          final post = savedPosts[index];
          print('Rendering saved post at index $index: ${post['postId']}');

          // Safely access post properties with null checks
          final List<dynamic>? contentList = post['content'];
          final bool hasMedia = contentList != null && contentList.isNotEmpty;
          final String mediaUrl = hasMedia ? contentList[0].toString() : '';
          final String description = post['description'] ?? '';
          final int likes = post['like'] is int ? post['like'] : 0;
          final int comments = post['comment'] is int ? post['comment'] : 0;
          final bool hasLikes = likes > 0;
          final bool hasComments = comments > 0;
          final String timeAgo = post['howMoneyMinutesAgo'] ??
              _getTimeAgo(post['createdAt'] ?? '');

          return GestureDetector(
            onTap: () {
              _showPostDetails(post);
            },
            child: Container(
              decoration: BoxDecoration(
                color: surfaceColor,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Post image
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        // Post content
                        hasMedia
                            ? CachedNetworkImage(
                                imageUrl: mediaUrl,
                                fit: BoxFit.cover,
                                placeholder: (context, url) => Container(
                                  color: surfaceColor,
                                  child: const Center(
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (context, url, error) => Container(
                                  color: surfaceColor,
                                  child: const Center(
                                    child: Icon(Icons.broken_image,
                                        color: Colors.white38, size: 30),
                                  ),
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(16),
                                color: cardColor,
                                alignment: Alignment.center,
                                child: Text(
                                  description.isNotEmpty
                                      ? description
                                      : 'Gönderi',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                  maxLines: 10,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),

                        // Video indicator
                        if (hasMedia && _isVideoFile(mediaUrl))
                          Positioned.fill(
                            child: Center(
                              child: Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.black.withOpacity(0.5),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.play_arrow,
                                  color: Colors.white,
                                  size: 24,
                                ),
                              ),
                            ),
                          ),

                        // Multiple media indicator
                        if (hasMedia && contentList!.length > 1)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.collections,
                                    color: Colors.white,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${contentList.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Location indicator
                        if (post['location'] != null &&
                            post['location'].toString().isNotEmpty)
                          Positioned(
                            bottom: 8,
                            left: 8,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.black.withOpacity(0.7),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    LineIcons.mapMarker,
                                    color: Colors.white,
                                    size: 12,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    post['location'].toString(),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 11,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                          ),

                        // Saved indicator
                        Positioned(
                          top: 8,
                          left: 8,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: accentColor.withOpacity(0.9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.bookmark,
                              color: Colors.white,
                              size: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Post footer
                  Padding(
                    padding: const EdgeInsets.all(10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Username
                        Text(
                          '@${post['username'] ?? 'Kullanıcı'}',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),

                        // Description
                        if (description.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Text(
                              description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),

                        const SizedBox(height: 6),

                        // Date & stats
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Flexible(
                              child: Text(
                                timeAgo,
                                style: TextStyle(
                                  color: Colors.grey[400],
                                  fontSize: 10,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            Row(
                              children: [
                                if (hasLikes)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: Row(
                                      children: [
                                        Icon(
                                          LineIcons.heart,
                                          color: Colors.red[400],
                                          size: 12,
                                        ),
                                        const SizedBox(width: 2),
                                        Text(
                                          likes.toString(),
                                          style: TextStyle(
                                            color: Colors.grey[400],
                                            fontSize: 10,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                if (hasComments)
                                  Row(
                                    children: [
                                      Icon(
                                        LineIcons.comment,
                                        color: Colors.grey[400],
                                        size: 12,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        comments.toString(),
                                        style: TextStyle(
                                          color: Colors.grey[400],
                                          fontSize: 10,
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ).animate().fadeIn(delay: (50 * index).ms, duration: 400.ms).moveY(
              begin: 20, end: 0, duration: 400.ms, curve: Curves.easeOutQuad);
        } catch (e) {
          print('Error rendering post at index $index: $e');
          return Container(); // Return an empty container if we can't render this post
        }
      },
    );
  }

  Widget _buildEmptyStateMessage({
    required IconData icon,
    required String title,
    required String message,
  }) {
    final theme = Provider.of<ThemeProvider>(context).currentTheme;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 64, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 64,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.poppins(
                color: theme.textTheme.titleLarge?.color,
                fontSize: 18,
                fontWeight: FontWeight.w500,
              ),
              textAlign: TextAlign.center,
            ),
            Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                message,
                style: TextStyle(
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7)),
                textAlign: TextAlign.center,
                overflow: TextOverflow.visible,
                softWrap: true,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivateAccountMessage() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock,
              size: 80,
              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.6),
            )
                .animate(
                    onPlay: (controller) => controller.repeat(reverse: true))
                .scaleXY(begin: 0.9, end: 1.1, duration: 2.seconds),
            const SizedBox(height: 24),
            Text(
              'Bu Hesap Gizli',
              style: GoogleFonts.poppins(
                color: theme.textTheme.titleLarge?.color,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Fotoğraf ve videoları görmek için bu hesabı takip etmelisiniz',
              style: GoogleFonts.poppins(
                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _toggleFollow,
              icon: const Icon(LineIcons.userPlus),
              label: Text(
                'Takip İsteği Gönder',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                foregroundColor: theme.colorScheme.onPrimary,
                padding:
                    const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ],
        ).animate(delay: 300.ms).fadeIn(duration: 700.ms),
      ),
    );
  }

  Widget _buildUserStatsSection() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;
    final _surfaceColor =
        themeProvider.isDarkMode ? AppColors.surfaceColor : Colors.grey[200]!;
    final _textColor = theme.textTheme.bodyLarge?.color ?? Colors.white;

    // AppColors.accentDark ve AppColors.lightAccentDark kullanmak yerine temayla uyumlu renkler kullanalım
    final primaryColor =
        themeProvider.isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final secondaryColor = primaryColor.withOpacity(0.8);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _surfaceColor.withOpacity(0.8),
            _surfaceColor.withOpacity(0.4),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: themeProvider.isDarkMode
              ? Colors.white.withOpacity(0.05)
              : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: themeProvider.isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.1),
            offset: const Offset(0, 4),
            blurRadius: 12,
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatItem(
            icon: Icons.grid_on_rounded,
            value: userProfile?['posts'] ?? 0,
            label: 'Gönderiler',
            color: primaryColor,
          ),
          // Takipçiler butonu
          InkWell(
            onTap: () {
              // Takipçiler sayfasına yönlendir
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowersScreen(
                    username: widget.username,
                  ),
                ),
              ).catchError((e) {
                print('Error navigating to FollowersScreen: $e');
                _showSnackBar('Takipçiler sayfasına erişilemedi: $e',
                    isError: true);
              });
            },
            child: _buildStatItem(
              icon: Icons.people_alt_rounded,
              value: userProfile?['follower'] ?? 0,
              label: 'Takipçiler',
              color: secondaryColor,
            ),
          ),
          // Takip edilenler butonu
          InkWell(
            onTap: () {
              // Takip edilenler sayfasına yönlendir
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => FollowingScreen(
                    username: widget.username,
                  ),
                ),
              ).catchError((e) {
                print('Error navigating to FollowingScreen: $e');
                _showSnackBar('Takip edilenler sayfasına erişilemedi: $e',
                    isError: true);
              });
            },
            child: _buildStatItem(
              icon: Icons.person_add_rounded,
              value: userProfile?['following'] ?? 0,
              label: 'Takip',
              color: primaryColor,
            ),
          ),
        ],
      ),
    ).animate(delay: 300.ms).fadeIn(duration: 500.ms);
  }
}
