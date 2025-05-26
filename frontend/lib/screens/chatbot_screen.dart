import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:developer' as developer;
import 'package:social_media/services/chatbotService.dart';
import 'package:flutter/rendering.dart';
import 'dart:math' as math;
import 'dart:ui'; // ImageFilter için gerekli import
import 'package:url_launcher/url_launcher.dart' as launcher;
import 'package:flutter_linkify/flutter_linkify.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:social_media/theme/app_theme.dart';

// API Constants
const String kBaseUrl = "http://192.168.89.61:8080/v1/api";
const String kChatEndpoint = "/chatbot/sendMessage";

// Hızlı komutlar
const List<Map<String, dynamic>> kQuickCommands = [
  // Akademik
  {
    'category': 'Akademik',
    'icon': Icons.school,
    'text': 'üniversite',
    'color': Color(0xFF5E72E4)
  },
  {
    'category': 'Akademik',
    'icon': Icons.calendar_today,
    'text': 'akademik takvim',
    'color': Color(0xFF5E72E4)
  },
  {
    'category': 'Akademik',
    'icon': Icons.school,
    'text': 'obs',
    'color': Color(0xFF5E72E4)
  },
  {
    'category': 'Akademik',
    'icon': Icons.book,
    'text': 'ders',
    'color': Color(0xFF5E72E4)
  },
  {
    'category': 'Akademik',
    'icon': Icons.assignment,
    'text': 'sınav',
    'color': Color(0xFF5E72E4)
  },
  {
    'category': 'Akademik',
    'icon': Icons.school,
    'text': 'mezuniyet',
    'color': Color(0xFF5E72E4)
  },

  // Kampüs
  {
    'category': 'Kampüs',
    'icon': Icons.location_city,
    'text': 'kampüs',
    'color': Color(0xFF11CDEF)
  },
  {
    'category': 'Kampüs',
    'icon': Icons.restaurant_menu,
    'text': 'yemekte ne var',
    'color': Color(0xFF11CDEF)
  },
  {
    'category': 'Kampüs',
    'icon': Icons.fastfood,
    'text': 'yemek',
    'color': Color(0xFF11CDEF)
  },
  {
    'category': 'Kampüs',
    'icon': Icons.home,
    'text': 'yurt',
    'color': Color(0xFF11CDEF)
  },
  {
    'category': 'Kampüs',
    'icon': Icons.hotel,
    'text': 'konaklama',
    'color': Color(0xFF11CDEF)
  },
  {
    'category': 'Kampüs',
    'icon': Icons.local_library,
    'text': 'kütüphane',
    'color': Color(0xFF11CDEF)
  },

  // Sosyal
  {
    'category': 'Sosyal',
    'icon': Icons.event,
    'text': 'etkinlik',
    'color': Color(0xFFFB6340)
  },
  {
    'category': 'Sosyal',
    'icon': Icons.palette,
    'text': 'hobi',
    'color': Color(0xFFFB6340)
  },
  {
    'category': 'Sosyal',
    'icon': Icons.sports_soccer,
    'text': 'spor',
    'color': Color(0xFFFB6340)
  },
  {
    'category': 'Sosyal',
    'icon': Icons.work,
    'text': 'kariyer',
    'color': Color(0xFFFB6340)
  },
  {
    'category': 'Sosyal',
    'icon': Icons.emoji_emotions,
    'text': 'motivasyon',
    'color': Color(0xFFFB6340)
  },

  // Hizmetler
  {
    'category': 'Hizmetler',
    'icon': Icons.people,
    'text': 'öğrenci işleri',
    'color': Color(0xFF2DCE89)
  },
  {
    'category': 'Hizmetler',
    'icon': Icons.monetization_on,
    'text': 'burs',
    'color': Color(0xFF2DCE89)
  },
  {
    'category': 'Hizmetler',
    'icon': Icons.directions_bus,
    'text': 'ulaşım',
    'color': Color(0xFF2DCE89)
  },
  {
    'category': 'Hizmetler',
    'icon': Icons.healing,
    'text': 'sağlık',
    'color': Color(0xFF2DCE89)
  },
  {
    'category': 'Hizmetler',
    'icon': Icons.phone_android,
    'text': 'mobil uygulama şifre',
    'color': Color(0xFF2DCE89)
  },

  // Diğer
  {
    'category': 'Diğer',
    'icon': Icons.wb_sunny,
    'text': 'hava nasıl',
    'color': Color(0xFFF5365C)
  },
  {
    'category': 'Diğer',
    'icon': Icons.computer,
    'text': 'teknoloji',
    'color': Color(0xFFF5365C)
  },
];

// Popüler sorular - Hızlı erişim için
const List<Map<String, dynamic>> kPopularQuestions = [
  {'icon': Icons.restaurant_menu, 'text': 'yemek', 'color': Color(0xFF11CDEF)},
  {'icon': Icons.wb_sunny, 'text': 'hava nasıl', 'color': Color(0xFFF5365C)},
  {'icon': Icons.campaign, 'text': 'Duyurular', 'color': Color(0xFF5E72E4)},
  {'icon': Icons.newspaper, 'text': 'Haberler', 'color': Color(0xFF2DCE89)},
];

class ChatbotScreen extends StatefulWidget {
  @override
  _ChatbotScreenState createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen>
    with SingleTickerProviderStateMixin {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _isTyping = false;
  late AnimationController _animationController;
  bool _isScrolling = false;
  bool _showScrollButton = false;

  // API related state
  String? _accessToken;
  bool _isTokenLoading = false;
  bool _isConnected = true;

  // Mesaj listesi
  List<Map<String, dynamic>> _messages = [
    {
      'isUser': false,
      'message':
          'Merhaba! Ben BinGoo Asistan. Üniversite ile ilgili sorularınızı yanıtlamak için buradayım. Aşağıdaki komutlardan birini seçebilir veya kendi sorunuzu yazabilirsiniz.',
      'time': DateTime.now().subtract(Duration(minutes: 1)),
      'isImage': false,
    },
  ];

  @override
  void initState() {
    super.initState();

    // Animasyon kontrolcüsü
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    // Mesajlar arasında kaydırma durumunu takip et
    _scrollController.addListener(_onScrollChange);

    // Access token'ı al
    _loadAccessToken();

    // Mesaj geçmişini yükle
    _loadMessageHistory();

    // Hoş geldin mesajını göster
    Future.delayed(Duration(milliseconds: 500), () {
      _scrollToBottom();
    });
  }

  void _onScrollChange() {
    // Scroll durumunu kontrol et
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    final atBottom = currentScroll >= (maxScroll - 50);

    // Scroll butonunu göster/gizle
    if (atBottom && _showScrollButton) {
      setState(() => _showScrollButton = false);
    } else if (!atBottom && !_showScrollButton && _messages.length > 4) {
      setState(() => _showScrollButton = true);
    }
  }

  @override
  void dispose() {
    // Mesaj geçmişini kaydet
    _saveMessageHistory();
    _messageController.dispose();
    _scrollController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  // Access token'ı shared preferences'dan yükle
  Future<void> _loadAccessToken() async {
    setState(() => _isTokenLoading = true);

    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('accessToken');

      setState(() {
        _accessToken = token;
        _isTokenLoading = false;
        _isConnected = token != null;
      });

      if (token == null) {
        // Sisteme bağlanmak için token gerekli - sessiz bir şekilde güncellemeyi bekle
        developer.log(
            'Chatbot: Access token bulunamadı. Kullanıcı henüz giriş yapmamış olabilir.',
            name: 'ChatbotScreen');
      } else {
        developer.log(
            'Chatbot: Access token yüklendi: ${token.substring(0, 10)}...',
            name: 'ChatbotScreen');
      }
    } catch (e) {
      setState(() => _isTokenLoading = false);
      developer.log('Chatbot: Token yüklenirken hata oluştu: $e',
          name: 'ChatbotScreen', error: e);
    }
  }

  // Access token'ı shared preferences'a kaydet
  Future<void> _saveAccessToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('accessToken', token);
      setState(() => _accessToken = token);
    } catch (e) {
      developer.log('Chatbot: Token kaydedilirken hata oluştu: $e',
          name: 'ChatbotScreen', error: e);
    }
  }

  // Mesaj gönderme
  Future<void> _sendMessage({String? text}) async {
    if (text == null || text.trim().isEmpty) return;

    final now = DateTime.now();

    setState(() {
      // Kullanıcı mesajını ekle
      _messages.add({
        'isUser': true,
        'message': text.trim(),
        'time': now,
        'isImage': false,
      });

      // Chatbot yazıyor...
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    // Geçmişi kaydet (kullanıcı mesajı)
    await _saveMessageHistory();

    try {
      // ChatbotService ile mesaj gönder
      final response = await ChatbotService.sendMessage(text.trim());

      String botResponse = '';

      if (response['success']) {
        // Başarılı cevap
        botResponse = response['message'];
        setState(() => _isConnected = true);
      } else {
        // Hata durumu
        botResponse = response['message'];

        // Yetkilendirme hatası ise token'ı temizle
        if (botResponse.contains('Oturum')) {
          _accessToken = null;
          final prefs = await SharedPreferences.getInstance();
          await prefs.remove('accessToken');
        }

        setState(() => _isConnected = false);
      }

      if (!mounted) return;

      setState(() {
        _isTyping = false;

        // Bot cevabını ekle
        _messages.add({
          'isUser': false,
          'message': botResponse,
          'time': DateTime.now(),
          'isImage': false,
        });
      });

      // Geçmişi kaydet (bot mesajı)
      await _saveMessageHistory();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isTyping = false;
        _isConnected = false;

        // Hata mesajı
        _messages.add({
          'isUser': false,
          'message':
              'Sunucuyla bağlantı kurulamadı. Lütfen internet bağlantınızı kontrol edin.',
          'time': DateTime.now(),
          'isImage': false,
        });
      });

      // Geçmişi kaydet (hata mesajı)
      await _saveMessageHistory();
    }

    _scrollToBottom();
  }

  // Scroll to bottom
  void _scrollToBottom() {
    Future.delayed(Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Geliştirme mesajı
  void _showDevelopmentMessage(String message) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    // Tema renklerini al
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;
    final successColor = theme.colorScheme.tertiary ?? Colors.green;
    final errorColor = theme.colorScheme.error;
    final textColor = theme.colorScheme.onBackground;
    final textSecondaryColor =
        theme.textTheme.bodySmall?.color ?? Colors.white70;

    // Kategori renklerini tema tipine göre ayarla
    Map<String, Color> categoryColors = getCategoryColors(themeProvider);

    final screenSize = MediaQuery.of(context).size;
    final bottomPadding = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        centerTitle: false,
        titleSpacing: 8,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new, size: 20, color: textColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: LayoutBuilder(
          builder: (context, constraints) {
            return Row(
              children: [
                // App Logo
                Hero(
                  tag: 'chatbot_logo',
                  child: Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: primaryColor.withOpacity(0.3),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                SizedBox(width: 10),

                // App Name and Status
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'BinGoo Asistan',
                      style: TextStyle(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                        fontSize: 16,
                        letterSpacing: 0.5,
                      ),
                    ),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedContainer(
                          duration: Duration(milliseconds: 300),
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: _isConnected ? successColor : errorColor,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _isConnected
                                    ? successColor.withOpacity(0.4)
                                    : errorColor.withOpacity(0.4),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          _isConnected ? 'Çevrimiçi' : 'Bağlantı Hatası',
                          style: TextStyle(
                            color: _isConnected ? successColor : errorColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            );
          },
        ),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                cardColor.withOpacity(0.9),
                cardColor.withOpacity(0.0),
              ],
            ),
          ),
        ),
        actions: [
          // Tüm komutları göster butonu
          IconButton(
            icon: Icon(Icons.grid_view_rounded, color: primaryColor),
            iconSize: 22,
            tooltip: 'Tüm Komutlar',
            onPressed: _showAllCommands,
          ),
          // Mesaj geçmişini temizle
          IconButton(
            icon: Icon(Icons.cleaning_services_rounded,
                color: primaryColor.withOpacity(0.7)),
            iconSize: 22,
            tooltip: 'Sohbeti temizle',
            onPressed: _clearChatHistory,
          ),
          // Info button
          IconButton(
            icon: Icon(Icons.info_outline_rounded, color: primaryColor),
            iconSize: 22,
            tooltip: 'Bilgi',
            padding: EdgeInsets.symmetric(horizontal: 12),
            onPressed: () {
              _showInfoDialog(
                  backgroundColor,
                  cardColor,
                  primaryColor,
                  accentColor,
                  textColor,
                  textSecondaryColor,
                  errorColor,
                  successColor);
            },
          ),
        ],
      ),
      body: Container(
        height: screenSize.height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: _getBackgroundGradient(themeProvider),
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Stack(
            children: [
              // Ana içerik
              Column(
                children: [
                  // Popüler Sorular
                  _buildPopularQuestions(),

                  // Mesaj listesi
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.transparent,
                      ),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: EdgeInsets.only(
                          left: 16,
                          right: 16,
                          top: 12,
                          bottom: 12 +
                              (bottomPadding > 0 ? bottomPadding * 0.7 : 0),
                        ),
                        physics: BouncingScrollPhysics(),
                        itemCount: _messages.length,
                        itemBuilder: (context, index) {
                          final message = _messages[index];
                          final isUser = message['isUser'] as bool;
                          final isImage = message['isImage'] as bool;
                          final isFirstMessage = index == 0;
                          final isLastMessage = index == _messages.length - 1;
                          final showAvatar = index == 0 ||
                              (index > 0 &&
                                  (_messages[index - 1]['isUser'] != isUser));
                          final showTimeInBubble = index == 0 ||
                              (index > 0 &&
                                  (_messages[index - 1]['isUser'] != isUser ||
                                      _messages[index]['time']
                                              .difference(
                                                  _messages[index - 1]['time'])
                                              .inMinutes >
                                          5));

                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: isLastMessage ? 0 : 10,
                              top: isFirstMessage ? 0 : 0,
                            ),
                            child: Column(
                              crossAxisAlignment: isUser
                                  ? CrossAxisAlignment.end
                                  : CrossAxisAlignment.start,
                              children: [
                                // Time header if messages are separated by time
                                if (index > 0 &&
                                    _messages[index]['time']
                                            .difference(
                                                _messages[index - 1]['time'])
                                            .inMinutes >
                                        15)
                                  _buildTimeHeader(_messages[index]['time']),

                                Row(
                                  mainAxisAlignment: isUser
                                      ? MainAxisAlignment.end
                                      : MainAxisAlignment.start,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    if (!isUser && showAvatar)
                                      _buildBotAvatar()
                                    else if (!isUser)
                                      SizedBox(width: 32),

                                    if (!isUser) SizedBox(width: 8),

                                    // Mesaj balonu
                                    Flexible(
                                      child: _buildMessageBubble(
                                          message,
                                          isUser,
                                          isImage,
                                          screenSize,
                                          showTimeInBubble),
                                    ),

                                    if (isUser) SizedBox(width: 8),
                                    if (isUser && showAvatar)
                                      _buildUserAvatar()
                                    else if (isUser)
                                      SizedBox(width: 32),
                                  ],
                                ),

                                // Zaman göstergesi sadece birkaç durumda gösterilir
                                if (!showTimeInBubble &&
                                    (isLastMessage ||
                                        (index < _messages.length - 1 &&
                                            _messages[index + 1]['isUser'] !=
                                                isUser)))
                                  Padding(
                                    padding: EdgeInsets.only(
                                      top: 4,
                                      right: isUser ? 40 : 0,
                                      left: !isUser ? 40 : 0,
                                    ),
                                    child: Text(
                                      _formatTime(message['time']),
                                      style: TextStyle(
                                        color:
                                            textSecondaryColor.withOpacity(0.6),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                  ),

                  // Chatbot yazıyor göstergesi
                  if (_isTyping)
                    Container(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      alignment: Alignment.centerLeft,
                      child: Row(
                        children: [
                          _buildBotAvatar(),
                          SizedBox(width: 12),
                          _buildTypingIndicator(),
                        ],
                      ),
                    ),

                  // Mesaj giriş alanı
                  _buildMessageInputArea(),
                ],
              ),

              // Aşağı kaydırma butonu
              if (_showScrollButton)
                Positioned(
                  right: 16,
                  bottom: 90,
                  child: AnimatedOpacity(
                    opacity: _showScrollButton ? 1.0 : 0.0,
                    duration: Duration(milliseconds: 200),
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withOpacity(0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: Icon(Icons.arrow_downward_rounded,
                            color: Colors.white),
                        onPressed: _scrollToBottom,
                        tooltip: 'Aşağı Kaydır',
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Temaya göre arka plan gradyeni
  List<Color> _getBackgroundGradient(ThemeProvider themeProvider) {
    switch (themeProvider.themeType) {
      case ThemeType.vaporwave:
        return [
          AppColors.vaporwaveBackground,
          Color(0xFF0A0118),
        ];
      case ThemeType.midnight:
        return [
          AppColors.midnightBackground,
          Color(0xFF091220),
        ];
      case ThemeType.nature:
        return [
          AppColors.natureBackground,
          Color(0xFF15211D),
        ];
      case ThemeType.cream:
        return [
          AppColors.creamBackground,
          Color(0xFFF3E9C6),
        ];
      case ThemeType.light:
        return [
          AppColors.lightBackground,
          Color(0xFFE8EAF0),
        ];
      default: // Dark
        return [
          AppColors.background,
          Color(0xFF0A0A0A),
        ];
    }
  }

  // Bot avatarı
  Widget _buildBotAvatar() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: primaryColor.withOpacity(0.2),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipOval(
        child: Image.asset(
          'assets/logo.png',
          fit: BoxFit.cover,
        ),
      ),
    );
  }

  // Mesaj balonu
  Widget _buildMessageBubble(Map<String, dynamic> message, bool isUser,
      bool isImage, Size screenSize, bool showTime) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;
    final textColor = theme.colorScheme.onBackground;
    final errorColor = theme.colorScheme.error;

    final messageText = message['message'] as String;

    // Temaya göre mesaj balonu renkleri
    final userGradient = _getUserMessageGradient(themeProvider);
    final botBubbleColor = cardColor.withOpacity(0.95);

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      curve: Curves.easeOutQuad,
      constraints: BoxConstraints(
        maxWidth: screenSize.width * 0.75,
      ),
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: isUser
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: userGradient,
              )
            : null,
        color: isUser ? null : botBubbleColor,
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomRight: isUser ? Radius.circular(4) : Radius.circular(20),
          bottomLeft: !isUser ? Radius.circular(4) : Radius.circular(20),
        ),
        boxShadow: [
          BoxShadow(
            color: isUser
                ? primaryColor.withOpacity(0.25)
                : Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 3),
            spreadRadius: 0,
          ),
        ],
        border: !isUser
            ? Border.all(
                color: Colors.white.withOpacity(0.08),
                width: 1,
              )
            : null,
      ),
      child: Stack(
        children: [
          // Shine effect overlay
          if (isUser)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.white.withOpacity(0.2),
                      Colors.white.withOpacity(0.0),
                    ],
                  ),
                ),
              ),
            ),

          Column(
            crossAxisAlignment:
                isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
            children: [
              // Link tespiti ve tıklanabilir bağlantılar
              Linkify(
                text: messageText,
                style: TextStyle(
                  color: isUser ? Colors.white : textColor,
                  fontSize: 15,
                  height: 1.4,
                ),
                linkStyle: TextStyle(
                  color: isUser ? Colors.white : accentColor,
                  fontSize: 15,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                  decoration: TextDecoration.underline,
                  decorationColor: isUser ? Colors.white70 : accentColor,
                  decorationThickness: 1.5,
                  backgroundColor: isUser
                      ? Colors.white.withOpacity(0.1)
                      : accentColor.withOpacity(0.1),
                ),
                onOpen: (link) async {
                  try {
                    // Parse URL string into Uri object
                    final Uri uri = Uri.parse(link.url);

                    // Try to launch URL in external browser
                    if (!await launcher.launchUrl(
                      uri,
                      mode: launcher.LaunchMode.externalApplication,
                    )) {
                      // If external launch fails, try fallback method
                      if (await launcher.canLaunch(link.url)) {
                        await launcher.launch(
                          link.url,
                          forceSafariVC: false,
                          forceWebView: false,
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Bağlantı açılamadı: ${link.url}'),
                            backgroundColor: errorColor,
                          ),
                        );
                      }
                    }
                  } catch (e) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('Hata: $e'),
                        backgroundColor: errorColor,
                      ),
                    );
                  }
                },
              ),
              if (showTime) SizedBox(height: 4),
              if (showTime)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isUser)
                      Icon(
                        Icons.done_all,
                        color: Colors.white60,
                        size: 12,
                      ),
                    if (isUser) SizedBox(width: 4),
                    Text(
                      _formatTime(message['time']),
                      style: TextStyle(
                        color: isUser ? Colors.white60 : Colors.white38,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  // Temaya göre kullanıcı mesajı gradyeni
  List<Color> _getUserMessageGradient(ThemeProvider themeProvider) {
    switch (themeProvider.themeType) {
      case ThemeType.vaporwave:
        return [
          AppColors.vaporwaveAccent.withOpacity(0.9),
          AppColors.vaporwaveButtonBackground.withOpacity(0.9),
        ];
      case ThemeType.midnight:
        return [
          AppColors.midnightAccent,
          AppColors.midnightAccent.withOpacity(0.7),
        ];
      case ThemeType.nature:
        return [
          AppColors.natureAccent,
          AppColors.natureAccent.withOpacity(0.7),
        ];
      case ThemeType.cream:
        return [
          AppColors.creamAccent,
          AppColors.creamAccent.withOpacity(0.7),
        ];
      case ThemeType.light:
        return [
          AppColors.lightAccent,
          AppColors.lightAccent.withOpacity(0.7),
        ];
      default: // Dark
        return [
          AppColors.accent,
          AppColors.accent.withOpacity(0.7),
        ];
    }
  }

  // Mesaj giriş alanı
  Widget _buildMessageInputArea() {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;
    final textColor = theme.colorScheme.onBackground;
    final textSecondaryColor =
        theme.textTheme.bodySmall?.color ?? Colors.white70;
    final errorColor = theme.colorScheme.error;

    final FocusNode focusNode = FocusNode();

    // Giriş alanı renkleri - tema uyumlu
    final inputBgColor = _getInputBackgroundColor(themeProvider);
    final inputBorderColor = _getInputBorderColor(themeProvider);
    final buttonColor = primaryColor;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cardColor.withOpacity(0.0),
            cardColor.withOpacity(0.95),
          ],
        ),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(28),
          topRight: Radius.circular(28),
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Bağlantı uyarısı
            if (!_isConnected)
              AnimatedContainer(
                duration: Duration(milliseconds: 300),
                margin: EdgeInsets.only(bottom: 12),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: errorColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: errorColor.withOpacity(0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: errorColor.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.wifi_off_rounded,
                        color: errorColor,
                        size: 14,
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Sunucu bağlantısı kesildi. Mesajlar gönderilemiyor.',
                        style: TextStyle(
                          color: errorColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton(
                      style: TextButton.styleFrom(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                        minimumSize: Size(60, 28),
                        backgroundColor: errorColor.withOpacity(0.1),
                        foregroundColor: errorColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        textStyle: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                      onPressed: () => setState(() => _isConnected = true),
                      child: Text('TEKRAR DENE'),
                    ),
                  ],
                ),
              ),

            // Öneri metni
            if (!_isTyping && _messages.length < 3)
              Padding(
                padding: const EdgeInsets.only(bottom: 12.0),
                child: Row(
                  children: [
                    Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: accentColor.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.lightbulb_outline,
                        color: accentColor,
                        size: 12,
                      ),
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'İpucu: "yemekte ne var", "akademik takvim" gibi sorular sorabilirsiniz.',
                        style: TextStyle(
                          color: accentColor,
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // Mesaj giriş alanı - Modern tasarım
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                color: inputBgColor,
                border: Border.all(
                  color: inputBorderColor,
                  width: 1.5,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 12,
                    spreadRadius: 0,
                    offset: Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Ekleme butonu (gelecek özellikler için)
                  IconButton(
                    icon: Icon(
                      Icons.add_circle_outline_rounded,
                      color: textSecondaryColor.withOpacity(0.7),
                      size: 22,
                    ),
                    onPressed: () {
                      // Gelecekte dosya ekleme veya başka özellikler için
                      _showDevelopmentMessage('Bu özellik yakında eklenecek');
                    },
                  ),

                  // Metin giriş alanı
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      focusNode: focusNode,
                      style: TextStyle(
                        color: textColor,
                        fontSize: 15,
                        height: 1.3,
                      ),
                      maxLines: 5,
                      minLines: 1,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: InputDecoration(
                        hintText: _isTyping
                            ? 'BinGoo yanıtlıyor...'
                            : 'Mesajınızı yazın...',
                        hintStyle: TextStyle(
                          color: textSecondaryColor.withOpacity(0.6),
                          fontSize: 15,
                        ),
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 12),
                        isDense: true,
                      ),
                      enabled: !_isTyping,
                      onTap: () {
                        // Klavyenin kapanmasını önle
                        if (!focusNode.hasFocus) {
                          focusNode.requestFocus();
                        }
                      },
                      onSubmitted: (text) {
                        if (text.isNotEmpty) {
                          _sendMessage(text: text);
                          // Mesaj gönderildikten sonra odağı korur
                          focusNode.requestFocus();
                        }
                      },
                    ),
                  ),

                  // Gönder butonu
                  Padding(
                    padding: const EdgeInsets.only(
                        right: 4.0, bottom: 4.0, top: 4.0),
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      decoration: BoxDecoration(
                        color: _messageController.text.isNotEmpty || _isTyping
                            ? buttonColor
                            : buttonColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                        boxShadow:
                            _messageController.text.isNotEmpty || _isTyping
                                ? [
                                    BoxShadow(
                                      color: buttonColor.withOpacity(0.4),
                                      blurRadius: 8,
                                      spreadRadius: 0,
                                      offset: Offset(0, 2),
                                    ),
                                  ]
                                : [],
                      ),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          borderRadius: BorderRadius.circular(20),
                          onTap: _isTyping
                              ? null
                              : () {
                                  final text = _messageController.text;
                                  if (text.isNotEmpty) {
                                    _sendMessage(text: text);
                                    // Mesaj gönderildikten sonra klavyeyi korur
                                    focusNode.requestFocus();
                                  }
                                },
                          child: Container(
                            padding: EdgeInsets.all(12),
                            child: _isTyping
                                ? SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    Icons.send_rounded,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tema uyumlu giriş alanı arkaplan rengi
  Color _getInputBackgroundColor(ThemeProvider themeProvider) {
    switch (themeProvider.themeType) {
      case ThemeType.vaporwave:
        return AppColors.vaporwaveCardBackground.withOpacity(0.8);
      case ThemeType.midnight:
        return AppColors.midnightCardBackground.withOpacity(0.8);
      case ThemeType.nature:
        return AppColors.natureCardBackground.withOpacity(0.8);
      case ThemeType.cream:
        return AppColors.creamCardBackground.withOpacity(0.8);
      case ThemeType.light:
        return AppColors.lightCardBackground.withOpacity(0.8);
      default: // Dark
        return AppColors.cardBackground.withOpacity(0.8);
    }
  }

  // Tema uyumlu giriş alanı çerçeve rengi
  Color _getInputBorderColor(ThemeProvider themeProvider) {
    switch (themeProvider.themeType) {
      case ThemeType.vaporwave:
        return AppColors.vaporwaveDivider.withOpacity(0.3);
      case ThemeType.midnight:
        return AppColors.midnightDivider.withOpacity(0.3);
      case ThemeType.nature:
        return AppColors.natureDivider.withOpacity(0.3);
      case ThemeType.cream:
        return AppColors.creamDivider.withOpacity(0.3);
      case ThemeType.light:
        return Colors.grey.withOpacity(0.3);
      default: // Dark
        return Colors.white.withOpacity(0.1);
    }
  }

  // Zaman başlığı
  Widget _buildTimeHeader(DateTime time) {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Center(
        child: TweenAnimationBuilder(
          tween: Tween<double>(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 500),
          curve: Curves.easeOutQuad,
          builder: (context, double value, child) {
            return Transform.scale(
              scale: value,
              child: Opacity(
                opacity: value,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: cardColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white10,
                      width: 0.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black12,
                        blurRadius: 8,
                        spreadRadius: 0,
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.access_time_rounded,
                        color: primaryColor.withOpacity(0.7),
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        _formatTimeHeader(time),
                        style: TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
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
    );
  }

  // Zaman başlığı formatı
  String _formatTimeHeader(DateTime time) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = DateTime(now.year, now.month, now.day - 1);
    final dateTime = DateTime(time.year, time.month, time.day);

    if (dateTime == today) {
      return 'Bugün ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else if (dateTime == yesterday) {
      return 'Dün ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    } else {
      return '${time.day}/${time.month}/${time.year} ${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    }
  }

  // Yazıyor göstergesi
  Widget _buildTypingIndicator() {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;

    return AnimatedContainer(
      duration: Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: cardColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(20).copyWith(
          bottomLeft: Radius.circular(0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
        border: Border.all(
          color: Colors.white.withOpacity(0.05),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'BinGoo yazıyor',
            style: TextStyle(
              color: primaryColor,
              fontSize: 13,
              fontWeight: FontWeight.w500,
            ),
          ),
          SizedBox(width: 12),
          _buildDot(delay: 0),
          _buildDot(delay: 300),
          _buildDot(delay: 600),
        ],
      ),
    );
  }

  Widget _buildDot({required int delay}) {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    return Container(
      margin: EdgeInsets.symmetric(horizontal: 2),
      child: JumpingDot(
        delay: delay,
        color: primaryColor.withOpacity(0.7),
      ),
    );
  }

  // Zaman formatı
  String _formatTime(DateTime time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  // Kullanıcı avatarı
  Widget _buildUserAvatar() {
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    bool isNewMessage = _messages.isNotEmpty &&
        _messages.last['isUser'] == true &&
        DateTime.now().difference(_messages.last['time']).inSeconds < 10;

    return PulseAvatar(
      isAnimating: isNewMessage,
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Colors.white.withOpacity(0.1),
              Colors.white.withOpacity(0.05),
            ],
          ),
          shape: BoxShape.circle,
          border: Border.all(color: primaryColor.withOpacity(0.4), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: primaryColor.withOpacity(0.2),
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Center(
          child: Icon(
            Icons.person,
            color: Colors.white.withOpacity(0.9),
            size: 16,
          ),
        ),
      ),
    );
  }

  // Bilgi dialogu
  void _showInfoDialog(
      Color backgroundColor,
      Color cardColor,
      Color primaryColor,
      Color accentColor,
      Color textColor,
      Color textSecondaryColor,
      Color errorColor,
      Color successColor) {
    final screenSize = MediaQuery.of(context).size;
    final smallScreen = screenSize.width < 360;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: cardColor.withOpacity(0.95),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.all(smallScreen ? 16.0 : 24.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: smallScreen ? 50 : 70,
                  height: smallScreen ? 50 : 70,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: primaryColor.withOpacity(0.3),
                        blurRadius: 12,
                        spreadRadius: 2,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: ClipOval(
                    child: Image.asset(
                      'assets/logo.png',
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                SizedBox(height: smallScreen ? 12 : 20),
                Text(
                  'BinGoo Asistan',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: smallScreen ? 18 : 22,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 8),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        primaryColor.withOpacity(0.2),
                        accentColor.withOpacity(0.2)
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Versiyon 1.1',
                    style: TextStyle(
                      color: primaryColor,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                SizedBox(height: smallScreen ? 12 : 20),
                Text(
                  'BinGoo Asistan, kampüs yaşamınızı kolaylaştırmak için tasarlanmış bir yapay zeka asistanıdır. Ders programları, etkinlikler, yemekhane menüsü ve daha fazlası hakkında bilgi alabilirsiniz.',
                  style: TextStyle(
                    color: textSecondaryColor,
                    fontSize: smallScreen ? 12 : 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: smallScreen ? 12 : 20),
                Container(
                  padding: EdgeInsets.all(smallScreen ? 12 : 16),
                  decoration: BoxDecoration(
                    color: backgroundColor.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isConnected
                          ? successColor.withOpacity(0.3)
                          : errorColor.withOpacity(0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: _isConnected
                                  ? successColor.withOpacity(0.1)
                                  : errorColor.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _isConnected ? Icons.cloud_done : Icons.cloud_off,
                              color: _isConnected ? successColor : errorColor,
                              size: smallScreen ? 16 : 20,
                            ),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'API Durumu',
                                  style: TextStyle(
                                    color: textColor,
                                    fontWeight: FontWeight.bold,
                                    fontSize: smallScreen ? 12 : 14,
                                  ),
                                ),
                                SizedBox(height: 2),
                                Text(
                                  _isConnected ? 'Bağlı' : 'Bağlantı Yok',
                                  style: TextStyle(
                                    color: _isConnected
                                        ? successColor
                                        : errorColor,
                                    fontWeight: FontWeight.w500,
                                    fontSize: smallScreen ? 12 : 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 12),
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.link,
                              color: primaryColor,
                              size: smallScreen ? 14 : 16,
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'API: $kBaseUrl$kChatEndpoint',
                                style: TextStyle(
                                  color: textSecondaryColor,
                                  fontSize: smallScreen ? 10 : 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: smallScreen ? 16 : 24),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: textColor,
                    elevation: 8,
                    shadowColor: primaryColor.withOpacity(0.4),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    minimumSize: Size(double.infinity, smallScreen ? 40 : 50),
                  ),
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    'Tamam',
                    style: TextStyle(
                      fontSize: smallScreen ? 14 : 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Mesaj geçmişini kaydet
  Future<void> _saveMessageHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // Mesajları JSON'a çevir
      final List<String> jsonMessages = _messages.map((msg) {
        return json.encode({
          ...msg,
          'time': msg['time'].millisecondsSinceEpoch,
        });
      }).toList();

      await prefs.setStringList('chatbot_messages', jsonMessages);
    } catch (e) {
      print('Mesaj geçmişi kaydedilirken hata oluştu: $e');
    }
  }

  // Mesaj geçmişini yükle
  Future<void> _loadMessageHistory() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonMessages = prefs.getStringList('chatbot_messages');

      if (jsonMessages == null || jsonMessages.isEmpty) return;

      // JSON'dan mesajları dönüştür
      final List<Map<String, dynamic>> loadedMessages =
          jsonMessages.map((jsonStr) {
        final map = json.decode(jsonStr) as Map<String, dynamic>;
        return {
          ...map,
          'time': DateTime.fromMillisecondsSinceEpoch(map['time'] as int),
        };
      }).toList();

      setState(() {
        // Karşılama mesajı + geçmiş mesajlar
        _messages = [_messages.first, ...loadedMessages.skip(1)];
      });
    } catch (e) {
      print('Mesaj geçmişi yüklenirken hata oluştu: $e');
    }
  }

  // Sohbet geçmişini temizle
  void _clearChatHistory() {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onBackground;
    final textSecondaryColor =
        theme.textTheme.bodySmall?.color ?? Colors.white70;
    final errorColor = theme.colorScheme.error;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Sohbeti Temizle',
          style: TextStyle(
            color: textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        content: Text(
          'Tüm sohbet geçmişiniz silinecek. Bu işlem geri alınamaz.',
          style: TextStyle(
            color: textSecondaryColor,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'İptal',
              style: TextStyle(
                color: textSecondaryColor,
              ),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: errorColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () {
              setState(() {
                // İlk karşılama mesajını koru, diğerlerini sil
                _messages = [_messages.first];
              });
              _saveMessageHistory();
              _scrollToBottom();
              Navigator.pop(context);
              _showDevelopmentMessage('Sohbet geçmişi temizlendi');
            },
            child: Text('Temizle'),
          ),
        ],
      ),
    );
  }

  // Popüler Sorular
  Widget _buildPopularQuestions() {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;
    final textColor = theme.colorScheme.onBackground;

    final screenSize = MediaQuery.of(context).size;
    final smallScreen = screenSize.width < 360;

    // Popüler sorulara renk atama
    final List<Map<String, dynamic>> topQuestions = kPopularQuestions
        .map((question) {
          // Eğer renk zaten varsa onu kullan, yoksa varsayılan renkleri ata
          if (question.containsKey('color') && question['color'] != null) {
            return question;
          } else {
            // Varsayılan renk ataması
            final Map<String, dynamic> updatedQuestion =
                Map<String, dynamic>.from(question);
            if (question['text'] == 'yemek') {
              updatedQuestion['color'] = Color(0xFF11CDEF); // Kampüs rengi
            } else if (question['text'] == 'hava nasıl') {
              updatedQuestion['color'] = Color(0xFFF5365C); // Diğer rengi
            } else if (question['text'] == 'Duyurular') {
              updatedQuestion['color'] = Color(0xFF5E72E4); // Akademik rengi
            } else if (question['text'] == 'Haberler') {
              updatedQuestion['color'] = Color(0xFF2DCE89); // Hizmetler rengi
            } else {
              updatedQuestion['color'] = primaryColor; // Varsayılan renk
            }
            return updatedQuestion;
          }
        })
        .take(4)
        .toList();

    return Container(
      padding:
          EdgeInsets.symmetric(horizontal: 16, vertical: smallScreen ? 8 : 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            cardColor.withOpacity(0.6),
            cardColor.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            spreadRadius: 0,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(smallScreen ? 6 : 8),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      primaryColor.withOpacity(0.2),
                      accentColor.withOpacity(0.2),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: primaryColor.withOpacity(0.1),
                      blurRadius: 6,
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Icon(
                  Icons.trending_up_rounded,
                  color: primaryColor,
                  size: smallScreen ? 14 : 16,
                ),
              ),
              SizedBox(width: 8),
              Text(
                'Popüler Sorular',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: smallScreen ? 12 : 14,
                ),
              ),
            ],
          ),
          SizedBox(height: smallScreen ? 8 : 12),

          // Responsive layout - Wrap ile otomatik satır kırma
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            children: topQuestions
                .map((question) => _buildQuestionSquare(
                    question,
                    (screenSize.width - 64) /
                        (smallScreen
                            ? 2
                            : 4) // Küçük ekranlarda 2, büyük ekranlarda 4 sütun
                    ))
                .toList(),
          ),
        ],
      ),
    );
  }

  // Kare şeklinde popüler soru kutusu
  Widget _buildQuestionSquare(Map<String, dynamic> question, double maxWidth) {
    final screenSize = MediaQuery.of(context).size;
    final smallScreen = screenSize.width < 360;
    final theme = Theme.of(context);
    final primaryColor = theme.colorScheme.primary;

    // Renk değeri kontrolü
    final Color questionColor =
        question.containsKey('color') && question['color'] != null
            ? question['color'] as Color
            : primaryColor;

    // Maksimum genişliği sınırla
    final itemWidth = math.min(maxWidth, 100.0);

    return InkWell(
      onTap: () => _sendMessage(text: question['text']),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: itemWidth,
        height: smallScreen ? itemWidth * 0.9 : itemWidth,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              questionColor.withOpacity(0.2),
              questionColor.withOpacity(0.1),
            ],
          ),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: questionColor.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(smallScreen ? 8 : 12),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: questionColor.withOpacity(0.2),
              ),
              child: Icon(
                question['icon'] as IconData,
                color: questionColor,
                size: smallScreen ? 16 : 24,
              ),
            ),
            SizedBox(height: smallScreen ? 4 : 8),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 6),
              child: Text(
                question['text'] as String,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: smallScreen ? 10 : 12,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Tüm komutları gösteren dialog
  void _showAllCommands() {
    final theme = Theme.of(context);
    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final primaryColor = theme.colorScheme.primary;
    final accentColor = theme.colorScheme.secondary;
    final textColor = theme.colorScheme.onBackground;
    final textSecondaryColor =
        theme.textTheme.bodySmall?.color ?? Colors.white70;

    // Kategori bazlı gruplanmış komutlar
    final Map<String, List<Map<String, dynamic>>> categorizedCommands = {};

    // Varsayılan kategori renkleri
    final Map<String, Color> categoryDefaultColors = {
      'Akademik': Color(0xFF5E72E4),
      'Kampüs': Color(0xFF11CDEF),
      'Sosyal': Color(0xFFFB6340),
      'Hizmetler': Color(0xFF2DCE89),
      'Diğer': Color(0xFFF5365C),
    };

    // Komutları kategorilerine göre grupla
    for (final command in kQuickCommands) {
      final category = command['category'] as String;
      if (!categorizedCommands.containsKey(category)) {
        categorizedCommands[category] = [];
      }

      // Komut renk kontrolü
      final Map<String, dynamic> updatedCommand =
          Map<String, dynamic>.from(command);
      if (!updatedCommand.containsKey('color') ||
          updatedCommand['color'] == null) {
        updatedCommand['color'] =
            categoryDefaultColors[category] ?? primaryColor;
      }

      categorizedCommands[category]!.add(updatedCommand);
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => StatefulBuilder(builder: (context, setState) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.9),
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            border: Border.all(
              color: Colors.white.withOpacity(0.1),
              width: 0.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle indicator
              Center(
                child: Container(
                  margin: EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              // Kapat çubuğu ve başlık
              Container(
                padding: EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      cardColor.withOpacity(0.5),
                      cardColor.withOpacity(0.2),
                    ],
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [primaryColor, accentColor],
                            ),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.3),
                                blurRadius: 10,
                                spreadRadius: 0,
                                offset: Offset(0, 3),
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.grid_view_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        SizedBox(width: 12),
                        Text(
                          'Tüm Komutlar',
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor.withOpacity(0.3),
                        shape: BoxShape.circle,
                      ),
                      child: IconButton(
                        icon: Icon(Icons.close, color: textSecondaryColor),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),

              // Komut kategorileri ve listesi
              Expanded(
                child: ListView(
                  padding: EdgeInsets.all(16),
                  children: [
                    for (final category in categorizedCommands.keys) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        child: Row(
                          children: [
                            Container(
                              padding: EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: categorizedCommands[category]!
                                    .first['color']
                                    .withOpacity(0.15),
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: [
                                  BoxShadow(
                                    color: categorizedCommands[category]!
                                        .first['color']
                                        .withOpacity(0.1),
                                    blurRadius: 8,
                                    spreadRadius: 0,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Icon(
                                categorizedCommands[category]!.first['icon']
                                    as IconData,
                                color: categorizedCommands[category]!
                                    .first['color'],
                                size: 18,
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              category,
                              style: TextStyle(
                                color: categorizedCommands[category]!
                                    .first['color'],
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final command in categorizedCommands[category]!)
                            InkWell(
                              onTap: () {
                                Navigator.pop(context);
                                _sendMessage(text: command['text']);
                              },
                              borderRadius: BorderRadius.circular(16),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: cardColor.withOpacity(0.6),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(
                                    color: command['color'].withOpacity(0.4),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.1),
                                      blurRadius: 8,
                                      offset: Offset(0, 3),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color:
                                            command['color'].withOpacity(0.15),
                                        shape: BoxShape.circle,
                                      ),
                                      child: Icon(
                                        command['icon'] as IconData,
                                        color: command['color'],
                                        size: 16,
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      command['text'] as String,
                                      style: TextStyle(
                                        color: textColor,
                                        fontSize: 14,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 8),
                      Divider(color: Colors.white12),
                    ],
                    SizedBox(height: 16),
                    Center(
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                          color: cardColor.withOpacity(0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white10,
                            width: 0.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.info_outline,
                              color: primaryColor,
                              size: 14,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Bir komuta tıklayarak hızlıca soru sorabilirsiniz',
                              style: TextStyle(
                                color: textSecondaryColor,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 30),
                  ],
                ),
              ),
            ],
          ),
        );
      }),
    );
  }

  // Kategori/komut renklerini tema tipine göre alma yardımcı fonksiyonu
  Map<String, Color> getCategoryColors(ThemeProvider themeProvider) {
    switch (themeProvider.themeType) {
      case ThemeType.vaporwave:
        return {
          'Akademik': Color(0xFF00FFFF),
          'Kampüs': Color(0xFFFF00FF),
          'Sosyal': Color(0xFFFFD200),
          'Hizmetler': Color(0xFF00FFAA),
          'Diğer': Color(0xFFFF6B6B),
        };
      case ThemeType.nature:
        return {
          'Akademik': Color(0xFF4CAF50),
          'Kampüs': Color(0xFF81C784),
          'Sosyal': Color(0xFFA5D6A7),
          'Hizmetler': Color(0xFFC8E6C9),
          'Diğer': Color(0xFF4CAF50),
        };
      case ThemeType.cream:
        return {
          'Akademik': Color(0xFFFF9800),
          'Kampüs': Color(0xFFFFA726),
          'Sosyal': Color(0xFFFFB74D),
          'Hizmetler': Color(0xFFFFCC80),
          'Diğer': Color(0xFFFFA000),
        };
      case ThemeType.midnight:
        return {
          'Akademik': Color(0xFF5E72E4),
          'Kampüs': Color(0xFF11CDEF),
          'Sosyal': Color(0xFFFB6340),
          'Hizmetler': Color(0xFF2DCE89),
          'Diğer': Color(0xFFF5365C),
        };
      default: // Dark ve Light için
        return {
          'Akademik': Color(0xFF5E72E4),
          'Kampüs': Color(0xFF11CDEF),
          'Sosyal': Color(0xFFFB6340),
          'Hizmetler': Color(0xFF2DCE89),
          'Diğer': Color(0xFFF5365C),
        };
    }
  }
}

// Zıplayan nokta animasyonu
class JumpingDot extends StatefulWidget {
  final int delay;
  final Color color;

  const JumpingDot({
    Key? key,
    required this.delay,
    this.color = Colors.white70,
  }) : super(key: key);

  @override
  _JumpingDotState createState() => _JumpingDotState();
}

class _JumpingDotState extends State<JumpingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600),
    );

    _animation = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) {
        _controller.repeat(reverse: true);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -5 * _animation.value),
          child: Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: widget.color,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(0.5),
                  blurRadius: 5,
                  spreadRadius: 0,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// Avatar için pulse animasyonu
class PulseAvatar extends StatefulWidget {
  final bool isAnimating;
  final Widget child;

  const PulseAvatar({
    Key? key,
    required this.isAnimating,
    required this.child,
  }) : super(key: key);

  @override
  _PulseAvatarState createState() => _PulseAvatarState();
}

class _PulseAvatarState extends State<PulseAvatar>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 1500),
    );

    if (widget.isAnimating) {
      _controller.repeat();
    }
  }

  @override
  void didUpdateWidget(PulseAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isAnimating && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.isAnimating && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        if (widget.isAnimating)
          AnimatedBuilder(
            animation: _controller,
            builder: (context, child) {
              return Container(
                width: 40 + (_controller.value * 10),
                height: 40 + (_controller.value * 10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [
                      Colors.white.withOpacity(0.0),
                      Colors.white.withOpacity(0.5 - _controller.value * 0.5),
                    ],
                    stops: [0.8, 1.0],
                    transform:
                        GradientRotation(_controller.value * 2 * math.pi),
                  ),
                ),
              );
            },
          ),
        widget.child,
      ],
    );
  }
}
