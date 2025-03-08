import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';

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
      // Karanlık mod ayarı
      final darkModeEnabled = prefs.getBool('dark_mode_enabled');
      // Konum paylaşımı
      final locationEnabled = prefs.getBool('location_enabled');
      // Profil gizliliği
      final profilePrivate = prefs.getBool('profile_private');
      // Kullanıcı bilgileri
      final profilePhotoUrl = prefs.getString('profile_photo_url');
      final username = prefs.getString('username');

      setState(() {
        _notificationsEnabled = notificationsEnabled ?? true;
        _darkModeEnabled = darkModeEnabled ?? true;
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

    // Gerçek dünya uygulamasında burada bir API çağrısı da olabilir
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ayarlar güncellendi'),
        duration: Duration(seconds: 1),
        backgroundColor: Colors.indigo,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          backgroundColor: Colors.black,
          title: const Text('Ayarlar', style: TextStyle(color: Colors.white)),
          iconTheme: const IconThemeData(color: Colors.white),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.white),
        ),
      );
    }

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Ayarlar', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        children: [
          // Kullanıcı bilgileri başlığı
          _buildSectionHeader('Hesap'),
          
          // Kullanıcı bilgileri
          ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.grey[800],
              backgroundImage: _profilePhotoUrl != null
                  ? CachedNetworkImageProvider(_profilePhotoUrl!)
                  : null,
              child: _profilePhotoUrl == null
                  ? const Icon(Icons.person, color: Colors.white)
                  : null,
            ),
            title: Text(
              _username ?? 'Kullanıcı',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            subtitle: const Text(
              'Profil bilgilerini düzenle',
              style: TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () => Navigator.pushNamed(context, '/edit-profile'),
          ),

          const Divider(color: Colors.white12),

          // Gizlilik ayarları
          _buildSectionHeader('Gizlilik'),

          _buildSwitchTile(
            title: 'Özel Profil',
            subtitle: 'Profiliniz sadece takipçileriniz tarafından görülebilir',
            value: _profilePrivate,
            onChanged: (value) {
              setState(() {
                _profilePrivate = value;
              });
              _savePreference('profile_private', value);
            },
          ),

          _buildSwitchTile(
            title: 'Konum Paylaşımı',
            subtitle: 'Gönderilerinizde konumunuzu paylaşın',
            value: _locationEnabled,
            onChanged: (value) {
              setState(() {
                _locationEnabled = value;
              });
              _savePreference('location_enabled', value);
            },
          ),

          // Bildirimler
          _buildSectionHeader('Bildirimler'),

          _buildSwitchTile(
            title: 'Bildirimler',
            subtitle: 'Tüm bildirimleri aç/kapat',
            value: _notificationsEnabled,
            onChanged: (value) {
              setState(() {
                _notificationsEnabled = value;
              });
              _savePreference('notifications_enabled', value);
            },
          ),

          ListTile(
            title: const Text(
              'Bildirim Tercihleri',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Hangi bildirimleri alacağınızı seçin',
              style: TextStyle(color: Colors.white70),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            enabled: _notificationsEnabled,
            onTap: () => Navigator.pushNamed(context, '/notification-preferences'),
          ),

          // Tema ayarları
          _buildSectionHeader('Görünüm'),

          _buildSwitchTile(
            title: 'Karanlık Mod',
            subtitle: 'Karanlık tema kullanın',
            value: _darkModeEnabled,
            onChanged: (value) {
              setState(() {
                _darkModeEnabled = value;
              });
              _savePreference('dark_mode_enabled', value);
            },
          ),

          // Güvenlik
          _buildSectionHeader('Güvenlik'),

          ListTile(
            leading: const Icon(Icons.lock, color: Colors.white),
            title: const Text(
              'Şifre Değiştir',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () => Navigator.pushNamed(context, '/change-password'),
          ),

          ListTile(
            leading: const Icon(Icons.security, color: Colors.white),
            title: const Text(
              'İki Faktörlü Doğrulama',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () => Navigator.pushNamed(context, '/two-factor-auth'),
          ),

          // Yardım ve Destek
          _buildSectionHeader('Yardım ve Destek'),

          ListTile(
            leading: const Icon(Icons.help_outline, color: Colors.white),
            title: const Text(
              'Yardım Merkezi',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () => Navigator.pushNamed(context, '/help-center'),
          ),

          ListTile(
            leading: const Icon(Icons.report_problem_outlined, color: Colors.white),
            title: const Text(
              'Sorun Bildir',
              style: TextStyle(color: Colors.white),
            ),
            trailing: const Icon(Icons.chevron_right, color: Colors.white),
            onTap: () => Navigator.pushNamed(context, '/report-problem'),
          ),

          // Hakkında
          _buildSectionHeader('Hakkında'),

          ListTile(
            leading: const Icon(Icons.info_outline, color: Colors.white),
            title: const Text(
              'Uygulama Bilgisi',
              style: TextStyle(color: Colors.white),
            ),
            subtitle: const Text(
              'Sürüm 1.0.0',
              style: TextStyle(color: Colors.white70),
            ),
            onTap: () => _showAboutDialog(),
          ),

          // Çıkış yap
          const SizedBox(height: 20),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
              ),
              onPressed: () => _showLogoutDialog(),
              child: const Text('Çıkış Yap'),
            ),
          ),

          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, top: 16, bottom: 8, right: 16),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          color: Colors.indigoAccent,
          fontSize: 14,
          fontWeight: FontWeight.bold,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
    bool enabled = true,
  }) {
    return SwitchListTile(
      title: Text(
        title,
        style: TextStyle(
          color: enabled ? Colors.white : Colors.white60,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: TextStyle(
          color: enabled ? Colors.white70 : Colors.white30,
        ),
      ),
      value: value,
      onChanged: enabled ? onChanged : null,
      activeColor: Colors.indigoAccent,
      inactiveThumbColor: Colors.grey,
      inactiveTrackColor: Colors.grey.withOpacity(0.5),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Uygulama Hakkında',
          style: TextStyle(color: Colors.white),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            Text(
              'Kampüs Sosyal Medya Uygulaması',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Sürüm: 1.0.0',
              style: TextStyle(color: Colors.white70),
            ),
            SizedBox(height: 8),
            Text(
              '© 2023 KampüsApp. Tüm hakları saklıdır.',
              style: TextStyle(color: Colors.white70),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'Tamam',
              style: TextStyle(color: Colors.indigoAccent),
            ),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: Colors.grey[900],
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(color: Colors.white),
        ),
        content: const Text(
          'Hesabınızdan çıkış yapmak istediğinizden emin misiniz?',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'İptal',
              style: TextStyle(color: Colors.white60),
            ),
          ),
          TextButton(
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
              style: TextStyle(color: Colors.redAccent),
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
} 