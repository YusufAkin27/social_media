import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:social_media/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';

class HelpCenterScreen extends StatefulWidget {
  const HelpCenterScreen({Key? key}) : super(key: key);

  @override
  _HelpCenterScreenState createState() => _HelpCenterScreenState();
}

class _HelpCenterScreenState extends State<HelpCenterScreen> {
  final List<Map<String, dynamic>> _faqCategories = [
    {
      'title': 'Hesap',
      'icon': CupertinoIcons.person_fill,
      'faqs': [
        {
          'question': 'Şifremi nasıl değiştirebilirim?',
          'answer':
              'Şifrenizi değiştirmek için "Ayarlar > Güvenlik > Şifre Değiştir" menüsüne gidin ve talimatları izleyin.'
        },
        {
          'question': 'Hesabımı nasıl silebilirim?',
          'answer':
              'Hesabınızı silmek için "Ayarlar > Hesap > Hesabı Sil" seçeneğine tıklayın. Bu işlem geri alınamaz ve tüm verileriniz silinecektir.'
        },
        {
          'question': 'Profilimi özel yapabilir miyim?',
          'answer':
              'Evet, "Ayarlar > Gizlilik > Özel Profil" seçeneğini etkinleştirerek profilinizi sadece takipçilerinizin görmesini sağlayabilirsiniz.'
        }
      ]
    },
    {
      'title': 'Gönderiler ve İçerik',
      'icon': CupertinoIcons.photo_fill,
      'faqs': [
        {
          'question': 'Bir gönderiyi nasıl silebilirim?',
          'answer':
              'Kendi gönderinize gidin, sağ üst köşedeki üç nokta simgesine tıklayın ve "Gönderiyi Sil" seçeneğini seçin.'
        },
        {
          'question':
              'Fotoğraf ve video kalitesi düşük çıkıyor, ne yapabilirim?',
          'answer':
              'Yükleme yaparken orijinal kalitede yükleme seçeneğini işaretlediğinizden emin olun. Ayrıca internet bağlantınızın hızlı ve kararlı olması önemlidir.'
        },
        {
          'question': 'İçerik kısıtlamaları nelerdir?',
          'answer':
              'Topluluk kurallarımıza aykırı, şiddet içeren, nefret söylemi barındıran veya telif hakkı ihlali olan içerikler yasaktır. Detaylı bilgi için Topluluk Kuralları sayfamızı ziyaret edin.'
        }
      ]
    },
    {
      'title': 'Bildirimler',
      'icon': CupertinoIcons.bell_fill,
      'faqs': [
        {
          'question': 'Bildirimlerimi nasıl özelleştirebilirim?',
          'answer':
              '"Ayarlar > Bildirimler > Bildirim Tercihleri" menüsünden hangi bildirim türlerini alacağınızı seçebilirsiniz.'
        },
        {
          'question': 'Bildirimler gelmiyor, ne yapmalıyım?',
          'answer':
              'Cihaz ayarlarınızdan uygulama bildirimlerinin açık olduğundan emin olun. Ayrıca "Ayarlar > Bildirimler" menüsünden bildirimlerin açık olduğunu kontrol edin.'
        }
      ]
    },
    {
      'title': 'Gizlilik ve Güvenlik',
      'icon': CupertinoIcons.lock_fill,
      'faqs': [
        {
          'question':
              'Engellediğim bir kullanıcının engelini nasıl kaldırabilirim?',
          'answer':
              '"Ayarlar > Gizlilik > Engellenen Kullanıcılar" menüsünden engellediğiniz kullanıcıları görebilir ve engellerini kaldırabilirsiniz.'
        },
        {
          'question': 'Rahatsız edici bir içeriği nasıl şikayet edebilirim?',
          'answer':
              'İçeriğin sağ üst köşesindeki üç nokta simgesine tıklayın ve "Şikayet Et" seçeneğini seçin. Şikayet nedeninizi belirtin ve gönderin.'
        },
        {
          'question': 'Verilerimin nasıl kullanıldığını nasıl öğrenebilirim?',
          'answer':
              'Gizlilik Politikamız, verilerinizin nasıl toplandığını ve kullanıldığını açıklar. "Ayarlar > Gizlilik > Gizlilik Politikası" menüsünden erişebilirsiniz.'
        }
      ]
    },
  ];

  // Kategori renklerini tema tipine göre alacak yardımcı fonksiyon
  Color getCategoryColor(BuildContext context, int index) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final accentColor = theme.colorScheme.primary;

    switch (index) {
      case 0:
        return themeProvider.themeType == ThemeType.vaporwave
            ? Color(0xFF00FFFF)
            : Color(0xFF00A8CC).withOpacity(0.8);
      case 1:
        return themeProvider.themeType == ThemeType.nature
            ? theme.colorScheme.primary
            : Color(0xFF45C4B0).withOpacity(0.8);
      case 2:
        return themeProvider.themeType == ThemeType.vaporwave
            ? Color(0xFFFF00FF)
            : Color(0xFF9DDE70).withOpacity(0.8);
      case 3:
        return themeProvider.themeType == ThemeType.cream
            ? theme.colorScheme.primary
            : Color(0xFFFF9D3D).withOpacity(0.8);
      default:
        return accentColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final accentColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onBackground;
    final textSecondaryColor =
        theme.textTheme.bodySmall?.color ?? Colors.white70;

    // Eklemeden önce kategorilere renk ata
    for (int i = 0; i < _faqCategories.length; i++) {
      _faqCategories[i]['color'] = getCategoryColor(context, i);
    }

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text(
          'Yardım Merkezi',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: IconThemeData(color: textColor),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildSearchBar(cardColor, textColor, textSecondaryColor),
          Expanded(
            child: ListView(
              padding: EdgeInsets.all(16),
              children: [
                _buildContactSupport(accentColor, textColor),
                SizedBox(height: 24),
                Text(
                  'Sık Sorulan Sorular',
                  style: TextStyle(
                    color: textColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                ..._faqCategories.map((category) => _buildFaqCategory(category,
                    cardColor, backgroundColor, textColor, textSecondaryColor)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar(
      Color cardColor, Color textColor, Color textSecondaryColor) {
    return Container(
      margin: EdgeInsets.all(16),
      padding: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: TextField(
        style: TextStyle(color: textColor),
        decoration: InputDecoration(
          hintText: 'Yardım konusu ara...',
          hintStyle: TextStyle(color: textSecondaryColor),
          icon: Icon(CupertinoIcons.search, color: textSecondaryColor),
          border: InputBorder.none,
        ),
      ),
    );
  }

  Widget _buildContactSupport(Color accentColor, Color textColor) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            accentColor,
            accentColor.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: accentColor.withOpacity(0.3),
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
                CupertinoIcons.chat_bubble_2_fill,
                color: Colors.white,
                size: 24,
              ),
              SizedBox(width: 12),
              Text(
                'Destek Ekibimize Ulaşın',
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
            'Sorularınız için 7/24 destek ekibimizle iletişime geçebilirsiniz.',
            style: TextStyle(
              color: Colors.white.withOpacity(0.9),
              fontSize: 14,
            ),
          ),
          SizedBox(height: 16),
          ElevatedButton(
            onPressed: () {
              // Destek talebi oluştur
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: accentColor,
              padding: EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: Center(
              child: Text(
                'Destek Talebi Oluştur',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFaqCategory(Map<String, dynamic> category, Color cardColor,
      Color backgroundColor, Color textColor, Color textSecondaryColor) {
    final categoryColor = category['color'] as Color;

    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ExpansionTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: categoryColor.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(
            category['icon'],
            color: categoryColor,
          ),
        ),
        title: Text(
          category['title'],
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        iconColor: textColor,
        collapsedIconColor: textSecondaryColor,
        children: [
          ListView.builder(
            shrinkWrap: true,
            physics: NeverScrollableScrollPhysics(),
            itemCount: category['faqs'].length,
            itemBuilder: (context, index) {
              final faq = category['faqs'][index];
              return _buildFaqItem(
                  faq, backgroundColor, textColor, textSecondaryColor);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildFaqItem(Map<String, dynamic> faq, Color backgroundColor,
      Color textColor, Color textSecondaryColor) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        border: Border(
          top: BorderSide(
            color: textSecondaryColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: ExpansionTile(
        title: Text(
          faq['question'],
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        iconColor: textColor,
        collapsedIconColor: textSecondaryColor,
        children: [
          Padding(
            padding: EdgeInsets.all(16),
            child: Text(
              faq['answer'],
              style: TextStyle(
                color: textSecondaryColor,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
