import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/cupertino.dart';
import 'dart:ui';
import 'package:social_media/screens/user_profile_screen.dart';
import 'package:social_media/services/studentService.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:social_media/models/student_dto.dart';
import 'dart:math' as math;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:line_icons/line_icons.dart';

class Sidebar extends StatefulWidget {
  final int initialIndex;
  final String profilePhotoUrl;

  const Sidebar({
    Key? key,
    this.initialIndex = 0,
    required this.profilePhotoUrl,
  }) : super(key: key);

  @override
  State<Sidebar> createState() => _SidebarState();
}

class _SidebarState extends State<Sidebar> with TickerProviderStateMixin {
  late int _currentIndex;
  late AnimationController _animationController;
  late AnimationController _bounceController;
  late AnimationController _rotationController;
  StudentDTO? _profileData;
  final StudentService _studentService = StudentService();
  bool _showLabels = false;

  final List<String> _labels = [
    'Ana Sayfa',
    'Keşfet',
    'Paylaş',
    'Bildirimler',
    'Profil'
  ];

  final List<IconData> _icons = [
    CupertinoIcons.home,
    CupertinoIcons.search,
    CupertinoIcons.plus,
    CupertinoIcons.bell,
    CupertinoIcons.person,
  ];

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _animationController.forward();
    _bounceController.repeat(reverse: true);

    _fetchProfileData();

    // Show labels after a short delay
    Future.delayed(const Duration(milliseconds: 300), () {
      setState(() {
        _showLabels = true;
      });
    });
  }

  Future<void> _fetchProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    final accessToken = prefs.getString('accessToken');

    if (accessToken != null) {
      try {
        final response = await _studentService.fetchProfile(accessToken);
        if (response.isSuccess && response.data != null) {
          setState(() {
            _profileData = response.data;
          });
        }
      } catch (e) {
        print('Profil verileri yüklenirken hata: $e');
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _bounceController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ModalRoute.of(context)?.settings.name ?? '';

    // Set the current index based on the route
    if (currentRoute.contains('/home')) {
      _currentIndex = 0;
    } else if (currentRoute.contains('/explore')) {
      _currentIndex = 1;
    } else if (currentRoute.contains('/notifications') ||
        currentRoute.contains('/notifications')) {
      _currentIndex = 3;
    } else if (currentRoute.contains('/profile-menu')) {
      _currentIndex = 4;
    }

    // Get safe area dimensions for responsive sizing
    final bottomPadding = MediaQuery.of(context).padding.bottom;
    final screenWidth = MediaQuery.of(context).size.width;

    // Calculate item size adaptively
    final double itemSize = (screenWidth / 5).clamp(48, 72);

    return Container(
      height: kBottomNavigationBarHeight + bottomPadding,
      decoration: BoxDecoration(
        // Arka planı tamamen şeffaf yapıyoruz
        color: Colors.transparent,
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: List.generate(5, (index) {
            return _buildNavItem(index, itemSize);
          }),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, double size) {
    final bool isSelected = _currentIndex == index;
    final Color activeColor = _getIconColor(index);

    // Middle button (add)
    if (index == 2) {
      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Container(
            width: size * 0.7,
            height: size * 0.7,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.purpleAccent,
                  Colors.blue,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.blue.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(LineIcons.plus, color: Colors.white),
              iconSize: size * 0.4,
              padding: EdgeInsets.zero,
              onPressed: () => _onNavigationTap(index),
              tooltip: _labels[index],
            ),
          ),
        ),
      );
    }

    // Profile button
    if (index == 4) {
      final String photoUrl =
          _profileData?.profilePhoto ?? widget.profilePhotoUrl;

      return SizedBox(
        width: size,
        height: size,
        child: Center(
          child: Container(
            width: size * 0.6,
            height: size * 0.6,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? activeColor : Colors.transparent,
                width: 2,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(size * 0.3),
                onTap: () => _onNavigationTap(index),
                child: Padding(
                  padding: const EdgeInsets.all(1),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(size * 0.3),
                    child: photoUrl.isNotEmpty
                        ? Image.network(
                            photoUrl,
                            fit: BoxFit.cover,
                            width: size * 0.55,
                            height: size * 0.55,
                            errorBuilder: (context, error, stackTrace) {
                              return CircleAvatar(
                                backgroundColor: Colors.grey[800],
                                child: Icon(
                                  LineIcons.user,
                                  color: Colors.white,
                                  size: size * 0.3,
                                ),
                              );
                            },
                          )
                        : CircleAvatar(
                            backgroundColor: Colors.grey[800],
                            child: Icon(
                              LineIcons.user,
                              color: Colors.white,
                              size: size * 0.3,
                            ),
                          ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }

    // Regular navigation items
    return SizedBox(
      width: size,
      height: size,
      child: Center(
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(size * 0.5),
            onTap: () => _onNavigationTap(index),
            child: Padding(
              padding: EdgeInsets.all(size * 0.15),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _icons[index],
                    color: isSelected ? activeColor : Colors.grey,
                    size: size * 0.35,
                  ),
                  const SizedBox(height: 2),
                  Container(
                    height: 3,
                    width: isSelected ? size * 0.15 : 0,
                    decoration: BoxDecoration(
                      color: activeColor,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _getIconColor(int index) {
    switch (index) {
      case 0: // Home
        return Colors.blue;
      case 1: // Explore
        return Colors.green;
      case 2: // Add
        return Colors.purple;
      case 3: // Notifications
        return Colors.orange;
      case 4: // Profile
        return Colors.purpleAccent;
      default:
        return Colors.white;
    }
  }

  void _onNavigationTap(int index) {
    // Aktif ikona tekrar basılması durumunda sayfayı yenileme işlevi
    if (_currentIndex == index) {
      _refreshCurrentPage(index);
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _currentIndex = index;
    });

    _navigateToPage(index);
  }

  void _refreshCurrentPage(int index) {
    HapticFeedback.lightImpact();

    switch (index) {
      case 0: // Home
        _refreshPage('/home');
        break;
      case 1: // Explore
        _refreshPage('/explore');
        break;
      case 2: // Add
        _showAddOptions(context);
        break;
      case 3: // Notifications
        _refreshPage('/notifications');
        break;
      case 4: // Profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(),
          ),
        );
        break;
    }
  }

  void _refreshPage(String route) {
    // Önce sayfayı yeniden yüklemek için mevcut routeun üzerine aynı routeu push yapıp hemen pop yapıyoruz
    Navigator.popAndPushNamed(context, route);

    // Varsa bir scroll controller'ı başa döndürme
    final scrollController = PrimaryScrollController.of(context);
    if (scrollController != null) {
      scrollController.animateTo(
        0,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutQuad,
      );
    }
  }

  void _navigateToPage(int index) {
    switch (index) {
      case 0: // Home
        Navigator.pushNamedAndRemoveUntil(context, '/home', (route) => false);
        break;

      case 1: // Explore
        Navigator.pushNamed(context, '/explore');
        break;

      case 2: // Add
        _showAddOptions(context);
        break;

      case 3: // Notifications
        Navigator.pushNamed(context, '/notifications');
        break;

      case 4: // Profile
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => UserProfileScreen(),
          ),
        );
        break;
    }
  }

  void _showAddOptions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(2),
                ),
                margin: const EdgeInsets.only(bottom: 20),
              ),
              _buildActionItem(
                icon: LineIcons.image,
                label: 'Fotoğraf Paylaş',
                color: Colors.blue,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/create-post');
                },
              ),
              _buildActionItem(
                icon: LineIcons.video,
                label: 'Video Paylaş',
                color: Colors.red,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/create-video');
                },
              ),
              _buildActionItem(
                icon: LineIcons.camera,
                label: 'Hikaye Paylaş',
                color: Colors.green,
                onTap: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/create-story');
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionItem({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color),
      ),
      title: Text(label),
      onTap: onTap,
    );
  }
}
