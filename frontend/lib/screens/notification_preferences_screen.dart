import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:social_media/theme/app_theme.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  _NotificationPreferencesScreenState createState() =>
      _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState
    extends State<NotificationPreferencesScreen> {
  bool _isLoading = true;

  // Notification settings
  bool _likesEnabled = true;
  bool _commentsEnabled = true;
  bool _followEnabled = true;
  bool _messagesEnabled = true;
  bool _postFromFollowingEnabled = true;
  bool _mentionsEnabled = true;
  bool _eventEnabled = true;
  bool _announcementsEnabled = true;

  // Notification sound settings
  String _notificationSound = 'Varsayılan';
  bool _vibrationEnabled = true;
  bool _ledEnabled = true;

  final List<String> _notificationSounds = [
    'Varsayılan',
    'Klasik',
    'Dijital',
    'Minimalist',
    'Yüksek',
    'Sessiz'
  ];

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();

      setState(() {
        _likesEnabled = prefs.getBool('notification_likes') ?? true;
        _commentsEnabled = prefs.getBool('notification_comments') ?? true;
        _followEnabled = prefs.getBool('notification_follow') ?? true;
        _messagesEnabled = prefs.getBool('notification_messages') ?? true;
        _postFromFollowingEnabled = prefs.getBool('notification_posts') ?? true;
        _mentionsEnabled = prefs.getBool('notification_mentions') ?? true;
        _eventEnabled = prefs.getBool('notification_events') ?? true;
        _announcementsEnabled =
            prefs.getBool('notification_announcements') ?? true;

        _notificationSound =
            prefs.getString('notification_sound') ?? 'Varsayılan';
        _vibrationEnabled = prefs.getBool('notification_vibration') ?? true;
        _ledEnabled = prefs.getBool('notification_led') ?? true;

        _isLoading = false;
      });
    } catch (e) {
      print('Error loading notification preferences: $e');
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
    }

    // Show a brief feedback to the user
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Ayarlar güncellendi'),
        duration: Duration(seconds: 1),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Tema provider'dan tema bilgilerini al
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Tema bazlı renkler
    final backgroundColor =
        isDarkMode ? AppColors.background : AppColors.lightBackground;
    final cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;
    final secondaryTextColor =
        isDarkMode ? AppColors.secondaryText : AppColors.lightSecondaryText;
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final dividerColor = isDarkMode ? AppColors.divider : Colors.grey.shade300;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'Bildirim Tercihleri',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildInfoCard(accentColor, textColor),
                SizedBox(height: 24),
                _buildSectionHeader('Bildirim Türleri', accentColor, textColor),
                _buildNotificationTypesCard(cardColor, textColor,
                    secondaryTextColor, accentColor, dividerColor),
                SizedBox(height: 24),
                _buildSectionHeader(
                    'Bildirim Sesi ve Titreşim', accentColor, textColor),
                _buildSoundAndVibrationCard(cardColor, backgroundColor,
                    textColor, secondaryTextColor, accentColor, dividerColor),
                SizedBox(height: 24),
                _buildResetButton(textColor, accentColor),
                SizedBox(height: 40),
              ],
            ),
    );
  }

  Widget _buildInfoCard(Color accentColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor.withOpacity(0.8),
            accentColor.withOpacity(0.6),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                CupertinoIcons.bell_fill,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Bildirim Tercihleri',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Text(
            'Hangi bildirimler alacağınızı ve nasıl alacağınızı özelleştirin. Bildirimleri tamamen kapatmak için "Ayarlar > Bildirimler" menüsünü kullanabilirsiniz.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, Color accentColor, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 16,
            decoration: BoxDecoration(
              color: accentColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              color: textColor,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationTypesCard(Color cardColor, Color textColor,
      Color secondaryTextColor, Color accentColor, Color dividerColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          _buildSwitchTile(
            title: 'Beğeniler',
            subtitle: 'Gönderileriniz beğenildiğinde bildirim alın',
            icon: CupertinoIcons.heart_fill,
            iconColor: Colors.red,
            value: _likesEnabled,
            onChanged: (value) {
              setState(() {
                _likesEnabled = value;
              });
              _savePreference('notification_likes', value);
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: accentColor,
          ),
          _buildDivider(dividerColor),
          _buildSwitchTile(
            title: 'Yorumlar',
            subtitle: 'Gönderilerinize yorum yapıldığında bildirim alın',
            icon: CupertinoIcons.chat_bubble_fill,
            iconColor: Colors.blue,
            value: _commentsEnabled,
            onChanged: (value) {
              setState(() {
                _commentsEnabled = value;
              });
              _savePreference('notification_comments', value);
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: accentColor,
          ),
          _buildDivider(dividerColor),
          _buildSwitchTile(
            title: 'Takip İstekleri',
            subtitle: 'Biri sizi takip ettiğinde bildirim alın',
            icon: CupertinoIcons.person_add_solid,
            iconColor: Colors.green,
            value: _followEnabled,
            onChanged: (value) {
              setState(() {
                _followEnabled = value;
              });
              _savePreference('notification_follow', value);
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: accentColor,
          ),
          _buildDivider(dividerColor),
          _buildSwitchTile(
            title: 'Mesajlar',
            subtitle: 'Yeni mesaj aldığınızda bildirim alın',
            icon: CupertinoIcons.envelope_fill,
            iconColor: Colors.amber,
            value: _messagesEnabled,
            onChanged: (value) {
              setState(() {
                _messagesEnabled = value;
              });
              _savePreference('notification_messages', value);
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: accentColor,
          ),
          _buildDivider(dividerColor),
          _buildSwitchTile(
            title: 'Takip Ettiklerinizden Gönderiler',
            subtitle:
                'Takip ettiğiniz kişiler gönderi paylaştığında bildirim alın',
            icon: CupertinoIcons.photo_fill,
            iconColor: Colors.purple,
            value: _postFromFollowingEnabled,
            onChanged: (value) {
              setState(() {
                _postFromFollowingEnabled = value;
              });
              _savePreference('notification_posts', value);
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: accentColor,
          ),
          _buildDivider(dividerColor),
          _buildSwitchTile(
            title: 'Bahsetmeler',
            subtitle:
                'Biri sizi bir gönderide veya yorumda etiketlediğinde bildirim alın',
            icon: CupertinoIcons.at,
            iconColor: Colors.orange,
            value: _mentionsEnabled,
            onChanged: (value) {
              setState(() {
                _mentionsEnabled = value;
              });
              _savePreference('notification_mentions', value);
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: accentColor,
          ),
          _buildDivider(dividerColor),
          _buildSwitchTile(
            title: 'Etkinlikler',
            subtitle: 'Yaklaşan etkinlikler hakkında bildirim alın',
            icon: CupertinoIcons.calendar_badge_plus,
            iconColor: Colors.teal,
            value: _eventEnabled,
            onChanged: (value) {
              setState(() {
                _eventEnabled = value;
              });
              _savePreference('notification_events', value);
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: accentColor,
          ),
          _buildDivider(dividerColor),
          _buildSwitchTile(
            title: 'Duyurular',
            subtitle: 'Kampüs duyuruları hakkında bildirim alın',
            icon: CupertinoIcons.bell_fill,
            iconColor: Colors.deepOrange,
            value: _announcementsEnabled,
            onChanged: (value) {
              setState(() {
                _announcementsEnabled = value;
              });
              _savePreference('notification_announcements', value);
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSoundAndVibrationCard(
      Color cardColor,
      Color backgroundColor,
      Color textColor,
      Color secondaryTextColor,
      Color accentColor,
      Color dividerColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: dividerColor.withOpacity(0.3),
        ),
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        CupertinoIcons.speaker_2_fill,
                        color: accentColor,
                        size: 20,
                      ),
                    ),
                    SizedBox(width: 12),
                    Text(
                      'Bildirim Sesi',
                      style: TextStyle(
                        color: textColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 16),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: dividerColor.withOpacity(0.3),
                    ),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _notificationSound,
                      isExpanded: true,
                      dropdownColor: cardColor,
                      icon: Icon(CupertinoIcons.chevron_down,
                          color: secondaryTextColor),
                      style: TextStyle(color: textColor),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            _notificationSound = newValue;
                          });
                          _savePreference('notification_sound', newValue);
                        }
                      },
                      items: _notificationSounds
                          .map<DropdownMenuItem<String>>((String value) {
                        return DropdownMenuItem<String>(
                          value: value,
                          child: Text(value),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          _buildDivider(dividerColor),
          _buildSwitchTile(
            title: 'Titreşim',
            subtitle: 'Bildirim geldiğinde titreşim',
            icon: CupertinoIcons.waveform,
            iconColor: accentColor,
            value: _vibrationEnabled,
            onChanged: (value) {
              setState(() {
                _vibrationEnabled = value;
              });
              _savePreference('notification_vibration', value);
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: accentColor,
          ),
          _buildDivider(dividerColor),
          _buildSwitchTile(
            title: 'LED Bildirimi',
            subtitle: 'Bildirim geldiğinde LED ışığı yanıp sönsün',
            icon: CupertinoIcons.lightbulb_fill,
            iconColor: AppColors.success,
            value: _ledEnabled,
            onChanged: (value) {
              setState(() {
                _ledEnabled = value;
              });
              _savePreference('notification_led', value);
            },
            textColor: textColor,
            secondaryTextColor: secondaryTextColor,
            accentColor: accentColor,
          ),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
    required bool value,
    required ValueChanged<bool> onChanged,
    required Color textColor,
    required Color secondaryTextColor,
    required Color accentColor,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: textColor,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          CupertinoSwitch(
            value: value,
            onChanged: onChanged,
            activeColor: accentColor,
            trackColor: secondaryTextColor.withOpacity(0.3),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(Color dividerColor) {
    return Divider(
      color: dividerColor.withOpacity(0.2),
      height: 1,
      indent: 16,
      endIndent: 16,
    );
  }

  Widget _buildResetButton(Color textColor, Color accentColor) {
    return TextButton(
      onPressed: () => _showResetConfirmation(textColor, accentColor),
      style: TextButton.styleFrom(
        foregroundColor: textColor.withOpacity(0.7),
      ),
      child: Text(
        'Varsayılan Ayarlara Sıfırla',
        style: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  void _showResetConfirmation(Color textColor, Color accentColor) {
    // Tema provider'dan tema bilgilerini al
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    final cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final secondaryTextColor =
        isDarkMode ? AppColors.secondaryText : AppColors.lightSecondaryText;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Ayarları Sıfırla',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Tüm bildirim ayarlarınız varsayılan değerlere sıfırlanacak. Devam etmek istiyor musunuz?',
          style: TextStyle(
            color: secondaryTextColor,
            fontSize: 14,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: secondaryTextColor,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              _resetToDefaults();
              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: accentColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Sıfırla',
              style: TextStyle(
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _resetToDefaults() async {
    setState(() {
      _likesEnabled = true;
      _commentsEnabled = true;
      _followEnabled = true;
      _messagesEnabled = true;
      _postFromFollowingEnabled = true;
      _mentionsEnabled = true;
      _eventEnabled = true;
      _announcementsEnabled = true;

      _notificationSound = 'Varsayılan';
      _vibrationEnabled = true;
      _ledEnabled = true;
    });

    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notification_likes', true);
    await prefs.setBool('notification_comments', true);
    await prefs.setBool('notification_follow', true);
    await prefs.setBool('notification_messages', true);
    await prefs.setBool('notification_posts', true);
    await prefs.setBool('notification_mentions', true);
    await prefs.setBool('notification_events', true);
    await prefs.setBool('notification_announcements', true);

    await prefs.setString('notification_sound', 'Varsayılan');
    await prefs.setBool('notification_vibration', true);
    await prefs.setBool('notification_led', true);

    // Tema provider'dan tema bilgilerini al
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Tüm ayarlar varsayılan değerlere sıfırlandı'),
        backgroundColor: accentColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
