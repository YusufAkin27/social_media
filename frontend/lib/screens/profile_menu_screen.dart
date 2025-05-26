import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart'; // Import for HapticFeedback
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:shimmer/shimmer.dart';
import 'package:social_media/services/studentService.dart';
import 'package:social_media/models/student_dto.dart';
import 'package:social_media/enums/faculty.dart';
import 'package:social_media/enums/department.dart';
import 'package:social_media/enums/grade.dart';
import 'dart:math';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter/rendering.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:social_media/theme/app_theme.dart';

class ProfileMenuScreen extends StatefulWidget {
  const ProfileMenuScreen({Key? key}) : super(key: key);

  @override
  _ProfileMenuScreenState createState() => _ProfileMenuScreenState();
}

class _ProfileMenuScreenState extends State<ProfileMenuScreen> {
  bool _isLoading = true;
  StudentDTO? _studentDTO;
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

      if (accessToken.isEmpty) {
        setState(() {
          _hasError = true;
          _errorMessage =
              'Oturum bilgisi bulunamadı. Lütfen tekrar giriş yapın.';
          _isLoading = false;
        });
        return;
      }

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
          final userData = responseData['data'];
          final studentDTO = StudentDTO.fromJson(userData);

          setState(() {
            _studentDTO = studentDTO;
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
      print('Profil yükleme hatası: $e');
      setState(() {
        _hasError = true;
        _errorMessage = 'Bağlantı hatası: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final dialogBackgroundColor =
        isDarkMode ? Colors.grey[900] : Colors.grey[100];
    final textColor = isDarkMode ? Colors.white : Colors.black;
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogBackgroundColor,
          title: Text('Çıkış Yap', style: TextStyle(color: textColor)),
          content: Text(
            'Hesabınızdan çıkış yapmak istediğinize emin misiniz?',
            style: TextStyle(color: textColor.withOpacity(0.7)),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('İptal',
                  style: TextStyle(color: textColor.withOpacity(0.6))),
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
              child: Text('Çıkış Yap', style: TextStyle(color: accentColor)),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Tema bazlı renkler
    final Color _primaryColor = isDarkMode
        ? const Color(0xFF3F51B5)
        : const Color(0xFF3F51B5); // Indigo
    final Color _secondaryColor = isDarkMode
        ? const Color(0xFF536DFE)
        : const Color(0xFF4FC3F7); // Lighter Indigo / Light Blue
    final Color _accentColor = isDarkMode
        ? AppColors.accent
        : AppColors.lightAccent; // Accent colors from theme
    final Color _backgroundColor =
        isDarkMode ? AppColors.background : AppColors.lightBackground;
    final Color _cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final Color _textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;
    final Color _secondaryTextColor =
        isDarkMode ? AppColors.secondaryText : AppColors.lightSecondaryText;

    return Scaffold(
      backgroundColor: _backgroundColor,
      body: _isLoading
          ? _buildLoadingIndicator(_primaryColor)
          : _hasError
              ? _buildErrorWidget(
                  _accentColor, _primaryColor, _backgroundColor, _textColor)
              : _buildProfileMenu(
                  _primaryColor,
                  _secondaryColor,
                  _accentColor,
                  _backgroundColor,
                  _cardColor,
                  _textColor,
                  _secondaryTextColor),
    );
  }

  Widget _buildProfileMenu(
      Color primaryColor,
      Color secondaryColor,
      Color accentColor,
      Color backgroundColor,
      Color cardColor,
      Color textColor,
      Color secondaryTextColor) {
    final screenWidth = MediaQuery.of(context).size.width;
    final horizontalPadding = screenWidth < 340 ? 12.0 : 20.0;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Modern, minimalist app bar
        SliverAppBar(
          title: const Text(
            'Profil',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
              fontSize: 22,
              letterSpacing: 0.5,
            ),
          ),
          centerTitle: true,
          floating: true,
          pinned: true,
          backgroundColor: backgroundColor,
          elevation: 0,
          expandedHeight: 60,
          flexibleSpace: FlexibleSpaceBar(
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    primaryColor.withOpacity(0.2),
                    backgroundColor,
                  ],
                ),
              ),
            ),
          ),
        ),

        // Main menu content
        SliverPadding(
          padding:
              EdgeInsets.symmetric(horizontal: horizontalPadding, vertical: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Section: Profile Management
              _buildSectionTitle('Profil Yönetimi', CupertinoIcons.person_fill,
                  primaryColor, textColor),
              const SizedBox(height: 12),
              _buildMenuCard([
                _buildMenuItem('Profili Düzenle', CupertinoIcons.pencil, () {
                  if (_studentDTO != null) {
                    Navigator.pushNamed(
                      context,
                      '/edit-profile',
                      arguments: {
                        'studentDTO': _studentDTO,
                      },
                    ).then((_) => _loadUserProfile());
                  } else {
                    Navigator.pushNamed(context, '/edit-profile')
                        .then((_) => _loadUserProfile());
                  }
                }, primaryColor, secondaryColor, textColor, secondaryTextColor),
                _buildMenuItem('Takipçiler', CupertinoIcons.person_2_fill,
                    () async {
                  final prefs = await SharedPreferences.getInstance();
                  final username = prefs.getString('username') ?? '';
                  Navigator.pushNamed(context, '/followers',
                      arguments: {'username': username});
                }, primaryColor, secondaryColor, textColor, secondaryTextColor),
                _buildMenuItem('Takip Edilenler', CupertinoIcons.person_2,
                    () async {
                  final prefs = await SharedPreferences.getInstance();
                  final username = prefs.getString('username') ?? '';
                  Navigator.pushNamed(context, '/following',
                      arguments: {'username': username});
                }, primaryColor, secondaryColor, textColor, secondaryTextColor),
                _buildMenuItem(
                    'Profil Sayfasına Git',
                    CupertinoIcons.person_crop_circle,
                    () => Navigator.pushNamed(context, '/user-profile',
                        arguments: {'userId': null, 'isCurrentUser': true}),
                    primaryColor,
                    secondaryColor,
                    textColor,
                    secondaryTextColor),
              ], cardColor),

              const SizedBox(height: 20),

              // Section: Content Management
              _buildSectionTitle('İçerik', CupertinoIcons.square_stack_fill,
                  primaryColor, textColor),
              const SizedBox(height: 12),
              _buildMenuCard([
                _buildMenuItem(
                    'Kaydedilen Gönderiler',
                    CupertinoIcons.bookmark,
                    () => Navigator.pushNamed(context, '/saved-posts'),
                    primaryColor,
                    secondaryColor,
                    textColor,
                    secondaryTextColor),
                _buildMenuItem(
                    'Beğenilen Gönderiler',
                    CupertinoIcons.heart,
                    () => Navigator.pushNamed(context, '/liked-posts'),
                    primaryColor,
                    secondaryColor,
                    textColor,
                    secondaryTextColor),
                _buildMenuItem(
                    'Beğenilen Hikayeler',
                    CupertinoIcons.heart_circle,
                    () => Navigator.pushNamed(context, '/liked-stories'),
                    primaryColor,
                    secondaryColor,
                    textColor,
                    secondaryTextColor),
                _buildMenuItem(
                    'Yorumlarım',
                    CupertinoIcons.chat_bubble_2,
                    () => Navigator.pushNamed(context, '/my-comments'),
                    primaryColor,
                    secondaryColor,
                    textColor,
                    secondaryTextColor),
                _buildMenuItem(
                    'Arşivlenen Gönderiler',
                    CupertinoIcons.archivebox,
                    () => Navigator.pushNamed(context, '/archived-posts'),
                    primaryColor,
                    secondaryColor,
                    textColor,
                    secondaryTextColor),
                _buildMenuItem(
                    'Arşivlenen Hikayeler',
                    CupertinoIcons.book,
                    () => Navigator.pushNamed(context, '/archived-stories'),
                    primaryColor,
                    secondaryColor,
                    textColor,
                    secondaryTextColor),
              ], cardColor),

              const SizedBox(height: 20),

              // Section: Settings
              _buildSectionTitle(
                  'Ayarlar', CupertinoIcons.gear_alt, primaryColor, textColor),
              const SizedBox(height: 12),
              _buildMenuCard([
                _buildMenuItem(
                    'Genel Ayarlar',
                    CupertinoIcons.settings,
                    () => Navigator.pushNamed(context, '/settings'),
                    primaryColor,
                    secondaryColor,
                    textColor,
                    secondaryTextColor),
                _buildMenuItem(
                    'Şifre Değiştir',
                    CupertinoIcons.lock_shield,
                    () => Navigator.pushNamed(context, '/change-password'),
                    primaryColor,
                    secondaryColor,
                    textColor,
                    secondaryTextColor),
                _buildMenuItem(
                    'İki Faktörlü Doğrulama',
                    CupertinoIcons.shield,
                    () => Navigator.pushNamed(context, '/two-factor-auth'),
                    primaryColor,
                    secondaryColor,
                    textColor,
                    secondaryTextColor),
              ], cardColor),

              const SizedBox(height: 40),

              // Logout Button
              _buildLogoutButton(accentColor, textColor),

              const SizedBox(height: 20),
            ]),
          ),
        ),
      ],
    );
  }

  Widget _buildLogoutButton(Color accentColor, Color textColor) {
    final screenWidth = MediaQuery.of(context).size.width;

    return Center(
      child: ElevatedButton.icon(
        onPressed: _logout,
        icon: const Icon(
          CupertinoIcons.square_arrow_right,
          color: Colors.white,
        ),
        label: const Text(
          'Çıkış Yap',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w500,
            letterSpacing: 0.5,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: accentColor,
          minimumSize: Size(min(screenWidth * 0.7, 180), 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 24),
        ),
      ),
    )
        .animate()
        .fadeIn(delay: 300.ms, duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _buildSectionTitle(
      String title, IconData icon, Color primaryColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 4.0),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              icon,
              color: primaryColor,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: textColor,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 300.ms)
        .slideX(begin: -0.05, end: 0);
  }

  Widget _buildMenuCard(List<Widget> items, Color cardColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Column(
        children: items,
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 400.ms);
  }

  Widget _buildMenuItem(
      String title,
      IconData iconData,
      VoidCallback onTap,
      Color primaryColor,
      Color secondaryColor,
      Color textColor,
      Color secondaryTextColor) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 340;

    return InkWell(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      borderRadius: BorderRadius.circular(12),
      splashColor: primaryColor.withOpacity(0.1),
      highlightColor: primaryColor.withOpacity(0.05),
      child: Padding(
        padding: EdgeInsets.symmetric(
            vertical: 14, horizontal: isSmallScreen ? 12 : 16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(iconData, color: secondaryColor, size: 20),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: textColor,
                ),
              ),
            ),
            Icon(
              CupertinoIcons.chevron_right,
              color: secondaryTextColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingIndicator(Color primaryColor) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final textColor = isDarkMode ? Colors.white70 : Colors.black54;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(color: primaryColor),
          const SizedBox(height: 16),
          Text(
            'Profil bilgileri yükleniyor...',
            style: TextStyle(color: textColor),
          )
        ],
      ),
    );
  }

  Widget _buildErrorWidget(Color accentColor, Color primaryColor,
      Color backgroundColor, Color textColor) {
    bool isConnectionError =
        _errorMessage?.toLowerCase().contains('connection') == true ||
            _errorMessage?.toLowerCase().contains('bağlantı') == true ||
            _errorMessage?.toLowerCase().contains('refused') == true ||
            _errorMessage?.toLowerCase().contains('timeout') == true ||
            _errorMessage?.toLowerCase().contains('zaman aşımı') == true;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
                isConnectionError
                    ? CupertinoIcons.wifi_slash
                    : CupertinoIcons.exclamationmark_circle,
                color: isConnectionError ? Colors.orange : accentColor,
                size: 60),
            const SizedBox(height: 16),
            Text(
              isConnectionError ? 'Bağlantı Hatası' : 'Hata',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(color: textColor),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: backgroundColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                isConnectionError
                    ? 'Sunucuya bağlanırken bir sorun oluştu. Lütfen internet bağlantınızı kontrol edin ve tekrar deneyin.'
                    : (_errorMessage ??
                        'Profil bilgileri yüklenirken bir hata oluştu.'),
                textAlign: TextAlign.center,
                style:
                    TextStyle(color: textColor.withOpacity(0.7), height: 1.4),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserProfile,
              icon: const Icon(CupertinoIcons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
