import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import '../theme/theme_provider.dart';
import '../theme/app_theme.dart';

// Renk paleti için sabitler - Bu sabitler tema değişikliğinde kullanılacak
const Color kPrimaryColor = Color(0xFF00A8CC);
const Color kSecondaryColor = Color(0xFF45C4B0);
const Color kAccentColor = Color(0xFF9DDE70);

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _isLoading = false;
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  bool _locationEnabled = true;
  bool _profilePrivate = false;
  String? _profilePhotoUrl;
  String? _username;

  @override
  void initState() {
    super.initState();
    _loadUserPreferences();
  }

  Future<void> _loadUserPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      // Bildirim ayarları
      final notificationsEnabled = prefs.getBool('notifications_enabled');
      // Konum paylaşımı
      final locationEnabled = prefs.getBool('location_enabled');
      // Profil gizliliği
      final profilePrivate = prefs.getBool('profile_private');
      // Kullanıcı bilgileri
      final profilePhotoUrl = prefs.getString('profile_photo_url');
      final username = prefs.getString('username');

      // ThemeProvider'dan tema ayarını al
      final themeProvider = Provider.of<ThemeProvider>(context, listen: false);

      setState(() {
        _notificationsEnabled = notificationsEnabled ?? true;
        _darkModeEnabled = themeProvider.isDarkMode;
        _locationEnabled = locationEnabled ?? true;
        _profilePrivate = profilePrivate ?? false;
        _profilePhotoUrl = profilePhotoUrl;
        _username = username;
        _isLoading = false;
      });
    } catch (e) {
      print('Ayarlar yüklenirken hata: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _savePreference(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();

    if (value is bool) {
      await prefs.setBool(key, value);
    } else if (value is String) {
      await prefs.setString(key, value);
    } else if (value is int) {
      await prefs.setInt(key, value);
    }

    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final accentColor =
        themeProvider.isDarkMode ? AppColors.accent : AppColors.lightAccent;

    // Gerçek dünya uygulamasında burada bir API çağrısı da olabilir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ayarlar güncellendi'),
        duration: Duration(seconds: 1),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Tema değişimine göre renkleri ayarla
    final backgroundColor = Theme.of(context).scaffoldBackgroundColor;
    final cardColor = Theme.of(context).cardColor;
    final textColor = Theme.of(context).textTheme.bodyLarge?.color;
    final textSecondaryColor = Theme.of(context).textTheme.bodySmall?.color;

    // Tema değişimine göre aksan ve vurgu renkleri
    final primaryColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final accentColor = isDarkMode ? AppColors.link : AppColors.lightLink;
    final dividerColor = isDarkMode ? Colors.white12 : Colors.black12;

    if (_isLoading) {
      return Scaffold(
        backgroundColor: backgroundColor,
        appBar: AppBar(
          backgroundColor: backgroundColor,
          title: Text('Ayarlar',
              style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
          iconTheme: IconThemeData(color: textColor),
          elevation: 0,
        ),
        body: Center(
          child: CircularProgressIndicator(color: primaryColor),
        ),
      );
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text('Ayarlar',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          // Kullanıcı bilgileri başlığı
          _buildSectionHeader('Hesap', textColor, primaryColor),

          // Kullanıcı bilgileri
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: cardColor.withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isDarkMode
                    ? Colors.white10
                    : Colors.black.withOpacity(0.05),
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(12),
              leading: CircleAvatar(
                radius: 28,
                backgroundColor: primaryColor.withOpacity(0.2),
                backgroundImage: _profilePhotoUrl != null
                    ? CachedNetworkImageProvider(_profilePhotoUrl!)
                    : null,
                child: _profilePhotoUrl == null
                    ? Icon(Icons.person, color: primaryColor, size: 32)
                    : null,
              ),
              title: Text(
                _username ?? 'Kullanıcı',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(
                  'Profil bilgilerini düzenle',
                  style: TextStyle(color: textSecondaryColor),
                ),
              ),
              trailing: Container(
                decoration: BoxDecoration(
                  color: primaryColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(8),
                child: Icon(Icons.edit, color: primaryColor),
              ),
              onTap: () => Navigator.pushNamed(context, '/edit-profile'),
            ),
          ),

          const SizedBox(height: 8),

          // Gizlilik ayarları
          _buildSectionHeader('Gizlilik', textColor, primaryColor),

          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Özel Profil',
              subtitle:
                  'Profiliniz sadece takipçileriniz tarafından görülebilir',
              icon: Icons.lock_outline,
              value: _profilePrivate,
              onChanged: (value) {
                setState(() {
                  _profilePrivate = value;
                });
                _savePreference('profile_private', value);
              },
              textColor: textColor,
              textSecondaryColor: textSecondaryColor,
              primaryColor: primaryColor,
            ),
            Divider(color: dividerColor, height: 1),
            _buildSwitchTile(
              title: 'Konum Paylaşımı',
              subtitle: 'Gönderilerinizde konumunuzu paylaşın',
              icon: Icons.location_on_outlined,
              value: _locationEnabled,
              onChanged: (value) {
                setState(() {
                  _locationEnabled = value;
                });
                _savePreference('location_enabled', value);
              },
              textColor: textColor,
              textSecondaryColor: textSecondaryColor,
              primaryColor: primaryColor,
            ),
          ], cardColor, isDarkMode),

          // Bildirimler
          _buildSectionHeader('Bildirimler', textColor, primaryColor),

          _buildSettingsCard([
            _buildSwitchTile(
              title: 'Bildirimler',
              subtitle: 'Tüm bildirimleri aç/kapat',
              icon: Icons.notifications_outlined,
              value: _notificationsEnabled,
              onChanged: (value) {
                setState(() {
                  _notificationsEnabled = value;
                });
                _savePreference('notifications_enabled', value);
              },
              textColor: textColor,
              textSecondaryColor: textSecondaryColor,
              primaryColor: primaryColor,
            ),
            Divider(color: dividerColor, height: 1),
            _buildListTile(
              title: 'Bildirim Tercihleri',
              subtitle: 'Hangi bildirimleri alacağınızı seçin',
              icon: Icons.tune,
              enabled: _notificationsEnabled,
              onTap: () =>
                  Navigator.pushNamed(context, '/notification-preferences'),
              textColor: textColor,
              textSecondaryColor: textSecondaryColor,
              primaryColor: primaryColor,
            ),
          ], cardColor, isDarkMode),

          // Tema ayarları
          _buildSectionHeader('Görünüm', textColor, primaryColor),

          _buildSettingsCard([
            _buildListTile(
              title: 'Tema Seçimi',
              subtitle: 'Uygulama temasını özelleştirin',
              icon: isDarkMode
                  ? Icons.dark_mode_outlined
                  : Icons.light_mode_outlined,
              onTap: () => Navigator.pushNamed(context, '/theme-selection'),
              textColor: textColor,
              textSecondaryColor: textSecondaryColor,
              primaryColor: primaryColor,
            ),
          ], cardColor, isDarkMode),

          // Güvenlik
          _buildSectionHeader('Güvenlik', textColor, primaryColor),

          _buildSettingsCard([
            _buildListTile(
              title: 'Şifre Değiştir',
              subtitle: 'Hesap şifrenizi güncelleyin',
              icon: Icons.lock_outline,
              onTap: () => Navigator.pushNamed(context, '/change-password'),
              textColor: textColor,
              textSecondaryColor: textSecondaryColor,
              primaryColor: primaryColor,
            ),
            Divider(color: dividerColor, height: 1),
            _buildListTile(
              title: 'İki Faktörlü Doğrulama',
              subtitle: 'Hesabınızı daha güvenli hale getirin',
              icon: Icons.security_outlined,
              onTap: () => Navigator.pushNamed(context, '/two-factor-auth'),
              textColor: textColor,
              textSecondaryColor: textSecondaryColor,
              primaryColor: primaryColor,
            ),
          ], cardColor, isDarkMode),

          // Yardım ve Destek
          _buildSectionHeader('Yardım ve Destek', textColor, primaryColor),

          _buildSettingsCard([
            _buildListTile(
              title: 'Yardım Merkezi',
              subtitle: 'Sık sorulan sorular ve destek',
              icon: Icons.help_outline,
              onTap: () => Navigator.pushNamed(context, '/help-center'),
              textColor: textColor,
              textSecondaryColor: textSecondaryColor,
              primaryColor: primaryColor,
            ),
            Divider(color: dividerColor, height: 1),
            _buildListTile(
              title: 'Sorun Bildir',
              subtitle: 'Karşılaştığınız sorunları bildirin',
              icon: Icons.report_problem_outlined,
              onTap: () => Navigator.pushNamed(context, '/report-problem'),
              textColor: textColor,
              textSecondaryColor: textSecondaryColor,
              primaryColor: primaryColor,
            ),
          ], cardColor, isDarkMode),

          // Hakkında
          _buildSectionHeader('Hakkında', textColor, primaryColor),

          _buildSettingsCard([
            _buildListTile(
              title: 'Uygulama Bilgisi',
              subtitle: 'Sürüm 1.0.0',
              icon: Icons.info_outline,
              onTap: () => _showAboutDialog(isDarkMode, textColor,
                  textSecondaryColor, cardColor, primaryColor),
              textColor: textColor,
              textSecondaryColor: textSecondaryColor,
              primaryColor: primaryColor,
            ),
          ], cardColor, isDarkMode),

          // Çıkış yap
          const SizedBox(height: 24),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
              ),
              onPressed: () => _showLogoutDialog(isDarkMode, textColor,
                  textSecondaryColor, cardColor, primaryColor),
              child: const Text(
                'Çıkış Yap',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, Color? textColor, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, top: 24, bottom: 12, right: 20),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: primaryColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: primaryColor,
              fontSize: 14,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
      List<Widget> children, Color? cardColor, bool isDarkMode) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: cardColor?.withOpacity(0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDarkMode ? Colors.white10 : Colors.black.withOpacity(0.05),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDarkMode
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
    Color? textColor,
    Color? textSecondaryColor,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: SwitchListTile(
        title: Text(
          title,
          style: TextStyle(
            color: enabled ? textColor : textColor?.withOpacity(0.5),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              color: enabled
                  ? textSecondaryColor
                  : textSecondaryColor?.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ),
        secondary: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled
                ? primaryColor.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: enabled ? primaryColor : Colors.grey,
            size: 24,
          ),
        ),
        value: value,
        onChanged: enabled ? onChanged : null,
        activeColor: primaryColor,
        activeTrackColor: primaryColor.withOpacity(0.3),
        inactiveThumbColor: Colors.grey,
        inactiveTrackColor: Colors.grey.withOpacity(0.3),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  Widget _buildListTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
    bool enabled = true,
    Color? textColor,
    Color? textSecondaryColor,
    required Color primaryColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: ListTile(
        title: Text(
          title,
          style: TextStyle(
            color: enabled ? textColor : textColor?.withOpacity(0.5),
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            subtitle,
            style: TextStyle(
              color: enabled
                  ? textSecondaryColor
                  : textSecondaryColor?.withOpacity(0.5),
              fontSize: 14,
            ),
          ),
        ),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: enabled
                ? primaryColor.withOpacity(0.2)
                : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            color: enabled ? primaryColor : Colors.grey,
            size: 24,
          ),
        ),
        trailing: enabled
            ? Icon(Icons.chevron_right, color: textSecondaryColor)
            : null,
        enabled: enabled,
        onTap: enabled ? onTap : null,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }

  void _showAboutDialog(bool isDarkMode, Color? textColor,
      Color? textSecondaryColor, Color? cardColor, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Uygulama Hakkında',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDarkMode
                    ? Theme.of(context).scaffoldBackgroundColor.withOpacity(0.5)
                    : Colors.grey.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: primaryColor.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.school, color: primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Kampüs Sosyal Medya',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Sürüm: 1.0.0',
                          style: TextStyle(color: textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              '© 2023 KampüsApp. Tüm hakları saklıdır.',
              style: TextStyle(color: textSecondaryColor, fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Tamam',
              style:
                  TextStyle(color: primaryColor, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(bool isDarkMode, Color? textColor,
      Color? textSecondaryColor, Color? cardColor, Color primaryColor) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Çıkış Yap',
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.warning_amber_rounded,
                      color: Colors.redAccent, size: 24),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
                      style: TextStyle(color: textColor, fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                  color: textSecondaryColor, fontWeight: FontWeight.w500),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            onPressed: () {
              // Çıkış işlemleri
              Navigator.pop(context); // Dialog'u kapat
              // Tüm kullanıcı bilgilerini temizle
              _clearUserData();
              // Login sayfasına yönlendir
              Navigator.pushNamedAndRemoveUntil(
                context,
                '/login',
                (route) => false,
              );
            },
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _clearUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('accessToken');
    // Diğer kullanıcı verileri de silinebilir
  }

  void _showThemeSelectionDialog(
    bool isDarkMode,
    Color? textColor,
    Color? textSecondaryColor,
    Color? cardColor,
    Color primaryColor,
  ) {
    Navigator.pushNamed(context, '/theme-selection');
  }
}
