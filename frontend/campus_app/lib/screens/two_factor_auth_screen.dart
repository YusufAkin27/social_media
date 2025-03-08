import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async';

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
        Uri.parse('http://localhost:8080/v1/api/auth/2fa/status'),
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
          _errorMessage = 'İki faktörlü doğrulama durumu alınamadı: ${response.statusCode}';
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
        Uri.parse('http://localhost:8080/v1/api/auth/2fa/generate'),
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
        Uri.parse('http://localhost:8080/v1/api/auth/2fa/enable'),
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
        Uri.parse('http://localhost:8080/v1/api/auth/2fa/disable'),
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
        const SnackBar(
          content: Text('Gizli anahtar panoya kopyalandı'),
          backgroundColor: Colors.indigoAccent,
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
          backgroundColor: Colors.grey[900],
          title: const Text(
            'İki Faktörlü Doğrulamayı Devre Dışı Bırak',
            style: TextStyle(color: Colors.white),
          ),
          content: const Text(
            'İki faktörlü doğrulamayı devre dışı bırakmak hesabınızın güvenliğini azaltacaktır. Devam etmek istediğinizden emin misiniz?',
            style: TextStyle(color: Colors.white70),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text(
                'İptal',
                style: TextStyle(color: Colors.white60),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text(
                'Devre Dışı Bırak',
                style: TextStyle(color: Colors.redAccent),
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
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('İki Faktörlü Doğrulama', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Colors.white))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: _is2FAEnabled ? _buildEnabledView() : _buildSetupView(),
            ),
    );
  }

  Widget _buildSetupView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Icon(
          Icons.security,
          color: Colors.indigoAccent,
          size: 48,
        ),
        const SizedBox(height: 16),
        Text(
          'Hesabınızı koruyun',
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 8),
        const Text(
          'İki faktörlü doğrulama, hesabınıza ekstra bir güvenlik katmanı ekler. Etkinleştirildiğinde, her oturum açtığınızda şifrenize ek olarak mobil uygulamadan bir kod girmeniz gerekecektir.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 24),
        
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        
        // QR kod görüntüleme veya oluşturma butonu
        if (_qrCodeUrl != null) ...[
          const Text(
            'Adım 1: QR kodunu tarayın',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Google Authenticator, Microsoft Authenticator veya benzer bir uygulamayı kullanarak aşağıdaki QR kodunu tarayın:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          
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
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Image.network(
                    _qrCodeUrl!,
                    fit: BoxFit.contain,
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return const Center(
                        child: CircularProgressIndicator(color: Colors.indigoAccent),
                      );
                    },
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Icon(Icons.error, color: Colors.red, size: 40),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Kalan süre: $_remainingTime saniye',
                  style: TextStyle(
                    color: _remainingTime > 10 ? Colors.white70 : Colors.redAccent,
                  ),
                ),
                TextButton.icon(
                  onPressed: _refreshQRCode,
                  icon: const Icon(Icons.refresh, color: Colors.indigoAccent),
                  label: const Text(
                    'Yenile',
                    style: TextStyle(color: Colors.indigoAccent),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          const Text(
            'QR kodu tarayamıyor musunuz?',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Aşağıdaki gizli anahtarı uygulamaya manuel olarak girebilirsiniz:',
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 8),
          
          // Gizli anahtar
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _secretKey!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontFamily: 'monospace',
                      letterSpacing: 1.2,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.copy, color: Colors.white70),
                  onPressed: _copySecretKey,
                  tooltip: 'Kopyala',
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          const Text(
            'Adım 2: Doğrulama kodu girin',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Uygulamada görünen 6 haneli doğrulama kodunu girin:',
            style: TextStyle(color: Colors.white70),
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
                    labelStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.dialpad, color: Colors.white60),
                    filled: true,
                    fillColor: Colors.grey[900],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: BorderSide.none,
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Colors.indigoAccent),
                    ),
                  ),
                  style: const TextStyle(color: Colors.white, letterSpacing: 8),
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
                      backgroundColor: Colors.indigoAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Doğrula ve Etkinleştir'),
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
                const Icon(
                  Icons.qr_code,
                  color: Colors.white70,
                  size: 80,
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: _generateQRCode,
                    icon: const Icon(Icons.security),
                    label: const Text('İki Faktörlü Doğrulamayı Ayarla'),
                    style: ElevatedButton.styleFrom(
                      foregroundColor: Colors.white,
                      backgroundColor: Colors.indigoAccent,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
        
        const SizedBox(height: 32),
        
        // Önerilen uygulamalar
        const Text(
          'Önerilen Doğrulayıcı Uygulamaları:',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
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
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                'İki Faktörlü Doğrulama Etkin',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hesabınız şu anda iki faktörlü doğrulama ile korunuyor. Her giriş yaptığınızda, doğrulayıcı uygulamanızdan bir kod girmeniz istenecektir.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        
        if (_errorMessage != null)
          Container(
            padding: const EdgeInsets.all(12),
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.red.withOpacity(0.5)),
            ),
            child: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              ],
            ),
          ),
        
        const Text(
          'Yedek Kurtarma Kodları',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Doğrulayıcı uygulamanıza erişemediğiniz durumlar için yedek kurtarma kodlarınızı güvenli bir yerde saklayın.',
          style: TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: () {
              // Kurtarma kodlarını görüntüleme
              Navigator.pushNamed(context, '/recovery-codes');
            },
            icon: const Icon(Icons.description, color: Colors.white),
            label: const Text('Kurtarma Kodlarını Görüntüle'),
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
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.red.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'İki Faktörlü Doğrulamayı Devre Dışı Bırak',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Güvenlik önlemi olarak, bu özelliği devre dışı bırakmak hesabınızın güvenliğini azaltacaktır.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _isVerifying ? null : _showDisableConfirmationDialog,
                  icon: const Icon(Icons.remove_circle_outline),
                  label: const Text('Devre Dışı Bırak'),
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.redAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAuthenticatorAppItem(String name, String developer, String imagePath) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 40,
            height: 40,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: const Icon(Icons.app_settings_alt, color: Colors.white70),
              // Gerçek uygulamada asset image kullanılabilir:
              // Image.asset(imagePath, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  developer,
                  style: const TextStyle(
                    color: Colors.white60,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: () {
              // Uygulama mağazasına yönlendirme
            },
            child: const Text(
              'İndir',
              style: TextStyle(color: Colors.indigoAccent),
            ),
          ),
        ],
      ),
    );
  }
} 