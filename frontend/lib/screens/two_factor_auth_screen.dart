import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';

class TwoFactorAuthScreen extends StatefulWidget {
  const TwoFactorAuthScreen({Key? key}) : super(key: key);

  @override
  _TwoFactorAuthScreenState createState() => _TwoFactorAuthScreenState();
}

class _TwoFactorAuthScreenState extends State<TwoFactorAuthScreen> {
  bool _isLoading = true;
  bool _is2FAEnabled = false;
  String? _qrCodeUrl;
  String? _secretKey;
  String? _errorMessage;
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _codeController = TextEditingController();
  bool _isVerifying = false;
  int _remainingTime = 30; // QR kod süresi (saniye)
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _check2FAStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _timer?.cancel();
    super.dispose();
  }

  // İki faktörlü doğrulama durumunu kontrol et
  Future<void> _check2FAStatus() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.get(
        Uri.parse('http://192.168.89.61:8080/v1/api/auth/2fa/status'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _is2FAEnabled = data['enabled'] ?? false;
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage =
              'İki faktörlü doğrulama durumu alınamadı: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
        _isLoading = false;
      });
    }
  }

  // QR Kodu ve gizli anahtarı oluştur
  Future<void> _generateQRCode() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.post(
        Uri.parse('http://192.168.89.61:8080/v1/api/auth/2fa/generate'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          _qrCodeUrl = data['qrCodeUrl'];
          _secretKey = data['secretKey'];
          _isLoading = false;
        });

        // QR kodun geçerlilik süresini başlat
        _startQrCodeTimer();
      } else {
        setState(() {
          _errorMessage = 'QR kod oluşturulamadı: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
        _isLoading = false;
      });
    }
  }

  // QR kodunun geçerlilik süresini başlat
  void _startQrCodeTimer() {
    _remainingTime = 30;
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        if (_remainingTime > 0) {
          _remainingTime--;
        } else {
          _timer?.cancel();
          _qrCodeUrl = null;
          _secretKey = null;
          // Timer süresi dolduğunda kullanıcıya bildirim göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  Icon(Icons.timer_off, color: Colors.white),
                  SizedBox(width: 10),
                  Text('QR kod süresi doldu. Lütfen yenileyin.'),
                ],
              ),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
              action: SnackBarAction(
                label: 'Yenile',
                textColor: Colors.white,
                onPressed: _refreshQRCode,
              ),
            ),
          );
        }
      });
    });
  }

  // QR kodu yenile
  void _refreshQRCode() {
    _timer?.cancel();
    _generateQRCode();
  }

  // İki faktörlü doğrulamayı etkinleştir
  Future<void> _enable2FA() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isVerifying = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.post(
        Uri.parse('http://192.168.89.61:8080/v1/api/auth/2fa/enable'),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'code': _codeController.text,
          'secretKey': _secretKey,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _is2FAEnabled = true;
          _qrCodeUrl = null;
          _secretKey = null;
          _isVerifying = false;
          _codeController.clear();
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İki faktörlü doğrulama başarıyla etkinleştirildi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? 'Doğrulama kodu geçersiz';
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
        _isVerifying = false;
      });
    }
  }

  // İki faktörlü doğrulamayı devre dışı bırak
  Future<void> _disable2FA() async {
    setState(() {
      _isVerifying = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.post(
        Uri.parse('http://192.168.89.61:8080/v1/api/auth/2fa/disable'),
        headers: {
          'Authorization': 'Bearer $accessToken',
        },
      );

      if (response.statusCode == 200) {
        setState(() {
          _is2FAEnabled = false;
          _isVerifying = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('İki faktörlü doğrulama devre dışı bırakıldı'),
            backgroundColor: Colors.orange,
          ),
        );
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? 'İşlem başarısız oldu';
          _isVerifying = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
        _isVerifying = false;
      });
    }
  }

  // Gizli anahtarı panoya kopyala
  void _copySecretKey() {
    if (_secretKey != null) {
      Clipboard.setData(ClipboardData(text: _secretKey!));
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.copy, color: Colors.white),
              SizedBox(width: 10),
              Text('Gizli anahtar panoya kopyalandı'),
            ],
          ),
          backgroundColor: Color(0xFF00A8CC),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    }
  }

  // Devre dışı bırakma onay dialotu
  Future<void> _showDisableConfirmationDialog() async {
    final bool? result = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: Color(0xFF1A2639),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded,
                  color: Colors.redAccent, size: 24),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'İki Faktörlü Doğrulamayı Devre Dışı Bırak',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.3)),
            ),
            child: const Text(
              'İki faktörlü doğrulamayı devre dışı bırakmak hesabınızın güvenliğini azaltacaktır. Devam etmek istediğinizden emin misiniz?',
              style: TextStyle(color: Colors.white, height: 1.4),
            ),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              style: TextButton.styleFrom(
                foregroundColor: Colors.white70,
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                'İptal',
                style: TextStyle(fontSize: 15),
              ),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              ),
              child: const Text(
                'Devre Dışı Bırak',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
            ),
          ],
        );
      },
    );

    if (result == true) {
      _disable2FA();
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return Scaffold(
      backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: themeProvider.currentTheme.scaffoldBackgroundColor,
        title: Text('İki Faktörlü Doğrulama',
            style: TextStyle(
                color: themeProvider.currentTheme.textTheme.bodyLarge?.color)),
        iconTheme: IconThemeData(
            color: themeProvider.currentTheme.textTheme.bodyLarge?.color),
      ),
      body: _isLoading
          ? Center(
              child: CircularProgressIndicator(
                  color: themeProvider.isDarkMode
                      ? Color(0xFF45C4B0)
                      : Theme.of(context).primaryColor))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _is2FAEnabled ? _buildEnabledView() : _buildSetupView(),
            ),
    );
  }

  Widget _buildSetupView() {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor =
        themeProvider.currentTheme.textTheme.bodyLarge?.color ?? Colors.white;
    final secondaryTextColor =
        themeProvider.isDarkMode ? Colors.white70 : Colors.black87;
    final accentColor = themeProvider.isDarkMode
        ? Color(0xFF00A8CC)
        : Theme.of(context).primaryColor;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.security,
          color: accentColor,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          'Hesabınızı koruyun',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: textColor,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        Text(
          'İki faktörlü doğrulama, hesabınıza ekstra bir güvenlik katmanı ekler. Etkinleştirildiğinde, her oturum açtığınızda şifrenize ek olarak mobil uygulamadan bir kod girmeniz gerekecektir.',
          style: TextStyle(color: secondaryTextColor),
        ),
        const SizedBox(height: 24),

        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),

        // QR kod görüntüleme veya oluşturma butonu
        if (_qrCodeUrl != null) ...[
          const SizedBox(height: 16),
          Text(
            'Adım 1: QR kodunu tarayın',
            style: TextStyle(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Google Authenticator, Microsoft Authenticator veya benzer bir uygulamayı kullanarak aşağıdaki QR kodunu tarayın:',
            style: TextStyle(color: secondaryTextColor, height: 1.4),
          ),
          const SizedBox(height: 20),

          // QR kod ve süre
          Center(
            child: Column(
              children: [
                Container(
                  width: 200,
                  height: 200,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Image.network(
                    _qrCodeUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Center(
                        child: CircularProgressIndicator(color: accentColor),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.error, color: Colors.red, size: 40),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _remainingTime > 10
                        ? (themeProvider.isDarkMode
                            ? Color(0xFF3F6B88).withOpacity(0.3)
                            : Theme.of(context).primaryColor.withOpacity(0.1))
                        : Colors.red
                            .withOpacity(themeProvider.isDarkMode ? 0.2 : 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _remainingTime > 10
                          ? (themeProvider.isDarkMode
                              ? Color(0xFF3F6B88).withOpacity(0.5)
                              : Theme.of(context).primaryColor.withOpacity(0.3))
                          : Colors.red.withOpacity(0.3),
                    ),
                  ),
                  child: Text(
                    'Kalan süre: $_remainingTime saniye',
                    style: TextStyle(
                      color: _remainingTime > 10
                          ? (themeProvider.isDarkMode
                              ? Colors.white70
                              : Theme.of(context).primaryColor)
                          : Colors.redAccent,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: _refreshQRCode,
                  icon: Icon(Icons.refresh, color: accentColor),
                  label: Text(
                    'Yenile',
                    style: TextStyle(color: accentColor),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Row(
            children: [
              Icon(Icons.key,
                  color: themeProvider.isDarkMode
                      ? Color(0xFF45C4B0)
                      : Theme.of(context).primaryColor,
                  size: 22),
              SizedBox(width: 10),
              Text(
                'QR kodu tarayamıyor musunuz?',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Aşağıdaki gizli anahtarı uygulamaya manuel olarak girebilirsiniz:',
            style: TextStyle(color: secondaryTextColor, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Gizli anahtar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: themeProvider.isDarkMode
                  ? LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF3F6B88).withOpacity(0.4),
                        Color(0xFF264E5C).withOpacity(0.4),
                      ],
                    )
                  : LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Theme.of(context).primaryColor.withOpacity(0.1),
                        Theme.of(context).primaryColor.withOpacity(0.15),
                      ],
                    ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: themeProvider.isDarkMode
                      ? Colors.white.withOpacity(0.1)
                      : Theme.of(context).primaryColor.withOpacity(0.2)),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 6,
                  spreadRadius: 1,
                ),
              ],
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _secretKey!,
                    style: TextStyle(
                      color: textColor,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                      fontSize: 16,
                    ),
                  ),
                ),
                Container(
                  decoration: BoxDecoration(
                    color: themeProvider.isDarkMode
                        ? Colors.white.withOpacity(0.1)
                        : Theme.of(context).primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: IconButton(
                    icon: Icon(Icons.copy, color: textColor),
                    onPressed: _copySecretKey,
                    tooltip: 'Kopyala',
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),
          Row(
            children: [
              Icon(Icons.check_circle_outline,
                  color: themeProvider.isDarkMode
                      ? Color(0xFF9DDE70)
                      : Colors.green,
                  size: 22),
              SizedBox(width: 10),
              Text(
                'Adım 2: Doğrulama kodu girin',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Uygulamada görünen 6 haneli doğrulama kodunu girin:',
            style: TextStyle(color: secondaryTextColor, height: 1.4),
          ),
          const SizedBox(height: 16),

          // Doğrulama kodu form
          Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _codeController,
                  decoration: InputDecoration(
                    labelText: 'Doğrulama Kodu',
                    labelStyle: TextStyle(color: secondaryTextColor),
                    prefixIcon: Icon(Icons.dialpad,
                        color: themeProvider.isDarkMode
                            ? Color(0xFF45C4B0)
                            : Theme.of(context).primaryColor),
                    filled: true,
                    fillColor: themeProvider.isDarkMode
                        ? Color(0xFF264E5C).withOpacity(0.3)
                        : Theme.of(context).cardColor,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: accentColor),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: themeProvider.isDarkMode
                              ? Colors.white.withOpacity(0.1)
                              : Theme.of(context).dividerColor),
                    ),
                  ),
                  style: TextStyle(
                      color: textColor, letterSpacing: 8, fontSize: 18),
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                  ],
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Doğrulama kodu gerekli';
                    }
                    if (value.length != 6) {
                      return '6 haneli kod girmelisiniz';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _enable2FA,
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Doğrula ve Etkinleştir',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ] else ...[
          // QR kod henüz oluşturulmadıysa gösterilecek buton
          Center(
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: themeProvider.isDarkMode
                        ? LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Color(0xFF3F6B88).withOpacity(0.5),
                              Color(0xFF264E5C).withOpacity(0.5),
                            ],
                          )
                        : LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Theme.of(context).primaryColor.withOpacity(0.2),
                              Theme.of(context).primaryColor.withOpacity(0.3),
                            ],
                          ),
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: Icon(
                    Icons.qr_code,
                    color: textColor,
                    size: 80,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generateQRCode,
                    icon: const Icon(Icons.security),
                    label: const Text(
                      'İki Faktörlü Doğrulamayı Ayarla',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: accentColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],

        const SizedBox(height: 40),

        // Önerilen uygulamalar
        Row(
          children: [
            Icon(Icons.apps, color: accentColor, size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                'Önerilen Doğrulayıcı Uygulamaları:',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                ),
                overflow: TextOverflow.ellipsis, // Taşma durumunda ... gösterir
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),
        _buildAuthenticatorAppItem(
          'Google Authenticator',
          'Google LLC',
          'assets/images/google_auth.png',
        ),
        const SizedBox(height: 8),
        _buildAuthenticatorAppItem(
          'Microsoft Authenticator',
          'Microsoft Corporation',
          'assets/images/ms_auth.png',
        ),
        const SizedBox(height: 8),
        _buildAuthenticatorAppItem(
          'Authy',
          'Twilio Inc.',
          'assets/images/authy.png',
        ),
      ],
    );
  }

  Widget _buildEnabledView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF9DDE70).withOpacity(0.2),
                Color(0xFF4DC672).withOpacity(0.2),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Color(0xFF9DDE70).withOpacity(0.3)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Color(0xFF9DDE70).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  color: Color(0xFF9DDE70),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'İki Faktörlü Doğrulama Etkin',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Hesabınız şu anda iki faktörlü doğrulama ile korunuyor. Her giriş yaptığınızda, doğrulayıcı uygulamanızdan bir kod girmeniz istenecektir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(16),
            margin: const EdgeInsets.only(bottom: 20),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red, size: 24),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 15),
                  ),
                ),
              ],
            ),
          ),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Color(0xFF3F6B88).withOpacity(0.3),
                Color(0xFF264E5C).withOpacity(0.3),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.vpn_key_outlined,
                      color: Color(0xFF45C4B0), size: 24),
                  SizedBox(width: 12),
                  Text(
                    'Yedek Kurtarma Kodları',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Doğrulayıcı uygulamanıza erişemediğiniz durumlar için yedek kurtarma kodlarınızı güvenli bir yerde saklayın.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    // Kurtarma kodlarını görüntüleme
                    Navigator.pushNamed(context, '/recovery-codes');
                  },
                  icon: const Icon(Icons.description, color: Color(0xFF45C4B0)),
                  label: const Text(
                    'Kurtarma Kodlarını Görüntüle',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: BorderSide(color: Color(0xFF45C4B0).withOpacity(0.5)),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        const Text(
          'Cihaz Yönetimi',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Hesabınıza bağlı tüm cihazları görüntüleyin ve yönetin.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Bağlı cihazlar sayfasına yönlendirme
              Navigator.pushNamed(context, '/connected-devices');
            },
            icon: const Icon(Icons.devices, color: Colors.white),
            label: const Text('Bağlı Cihazları Yönet'),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Colors.white30),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ),
        const SizedBox(height: 40),
        const Divider(color: Colors.white10),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.red.withOpacity(0.2),
                Colors.redAccent.withOpacity(0.1),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.warning_amber_rounded,
                      color: Colors.redAccent, size: 24),
                  SizedBox(width: 12),
                  Text(
                    'İki Faktörlü Doğrulamayı Devre Dışı Bırak',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              const Text(
                'Güvenlik önlemi olarak, bu özelliği devre dışı bırakmak hesabınızın güvenliğini azaltacaktır.',
                style: TextStyle(color: Colors.white70, height: 1.4),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed:
                      _isVerifying ? null : _showDisableConfirmationDialog,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text(
                    'Devre Dışı Bırak',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 2,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatorAppItem(
      String name, String developer, String imagePath) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final textColor =
        themeProvider.currentTheme.textTheme.bodyLarge?.color ?? Colors.white;
    final secondaryTextColor =
        themeProvider.isDarkMode ? Colors.white60 : Colors.black87;
    final accentColor = themeProvider.isDarkMode
        ? Color(0xFF00A8CC)
        : Theme.of(context).primaryColor;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: themeProvider.isDarkMode
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF3F6B88).withOpacity(0.3),
                  Color(0xFF264E5C).withOpacity(0.3),
                ],
              )
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Theme.of(context).primaryColor.withOpacity(0.05),
                  Theme.of(context).primaryColor.withOpacity(0.1),
                ],
              ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: themeProvider.isDarkMode
                ? Colors.white.withOpacity(0.1)
                : Theme.of(context).primaryColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            padding: EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: themeProvider.isDarkMode
                  ? Colors.white.withOpacity(0.1)
                  : Theme.of(context).primaryColor.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(Icons.app_settings_alt,
                color: themeProvider.isDarkMode
                    ? Color(0xFF45C4B0)
                    : Theme.of(context).primaryColor),
            // Gerçek uygulamada asset image kullanılabilir:
            // Image.asset(imagePath, fit: BoxFit.cover),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  developer,
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Color(0xFF00A8CC).withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextButton(
              onPressed: () {
                // Uygulama mağazasına yönlendirme
              },
              style: TextButton.styleFrom(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              ),
              child: const Text(
                'İndir',
                style: TextStyle(
                  color: Color(0xFF00A8CC),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
