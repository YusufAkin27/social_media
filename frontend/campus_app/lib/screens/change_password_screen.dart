import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  bool _isCurrentPasswordVisible = false;
  bool _isNewPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // Şifre güçlülük derecesini hesapla
  double _calculatePasswordStrength(String password) {
    double strength = 0;
    
    // Uzunluk kontrolü
    if (password.length >= 8) strength += 0.2;
    if (password.length >= 12) strength += 0.2;
    
    // Karakter çeşitliliği kontrolü
    final hasUppercase = password.contains(RegExp(r'[A-Z]'));
    final hasLowercase = password.contains(RegExp(r'[a-z]'));
    final hasDigits = password.contains(RegExp(r'[0-9]'));
    final hasSpecialChars = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    
    if (hasUppercase) strength += 0.15;
    if (hasLowercase) strength += 0.15;
    if (hasDigits) strength += 0.15;
    if (hasSpecialChars) strength += 0.15;
    
    return strength.clamp(0.0, 1.0);
  }

  // Şifre güçlülük durumunu metin olarak ifade et
  String _getPasswordStrengthText(double strength) {
    if (strength < 0.3) return 'Zayıf';
    if (strength < 0.7) return 'Orta';
    return 'Güçlü';
  }

  // Şifre güçlülük göstergesi rengi
  Color _getPasswordStrengthColor(double strength) {
    if (strength < 0.3) return Colors.red;
    if (strength < 0.7) return Colors.orange;
    return Colors.green;
  }

  Future<void> _changePassword() async {
    // Form doğrulama kontrolü
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Yeni şifre ve tekrarının eşleşip eşleşmediğini kontrol et
    if (_newPasswordController.text != _confirmPasswordController.text) {
      setState(() {
        _errorMessage = 'Yeni şifre ve tekrarı eşleşmiyor.';
        _successMessage = null;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _successMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      final response = await http.post(
        Uri.parse('http://localhost:8080/v1/api/auth/change-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'currentPassword': _currentPasswordController.text,
          'newPassword': _newPasswordController.text,
        }),
      );

      if (response.statusCode == 200) {
        setState(() {
          _successMessage = 'Şifreniz başarıyla değiştirildi.';
          _currentPasswordController.clear();
          _newPasswordController.clear();
          _confirmPasswordController.clear();
          _isLoading = false;
        });
      } else {
        final responseData = jsonDecode(response.body);
        setState(() {
          _errorMessage = responseData['message'] ?? 'Şifre değiştirme sırasında bir hata oluştu.';
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

  @override
  Widget build(BuildContext context) {
    final strength = _newPasswordController.text.isEmpty 
        ? 0.0 
        : _calculatePasswordStrength(_newPasswordController.text);
    
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Şifre Değiştir', style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Şifrenizi değiştirmek için önce mevcut şifrenizi doğrulamanız gerekiyor.',
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 24),
              // Mevcut şifre alanı
              TextFormField(
                controller: _currentPasswordController,
                decoration: InputDecoration(
                  labelText: 'Mevcut Şifre',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.lock_outline, color: Colors.white60),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isCurrentPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white60,
                    ),
                    onPressed: () {
                      setState(() {
                        _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                      });
                    },
                  ),
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
                style: const TextStyle(color: Colors.white),
                obscureText: !_isCurrentPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen mevcut şifrenizi girin.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              // Yeni şifre alanı
              TextFormField(
                controller: _newPasswordController,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white60),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isNewPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white60,
                    ),
                    onPressed: () {
                      setState(() {
                        _isNewPasswordVisible = !_isNewPasswordVisible;
                      });
                    },
                  ),
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
                style: const TextStyle(color: Colors.white),
                obscureText: !_isNewPasswordVisible,
                onChanged: (value) {
                  setState(() {});
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen yeni şifre girin.';
                  }
                  if (value.length < 8) {
                    return 'Şifre en az 8 karakter uzunluğunda olmalıdır.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 8),
              // Şifre güçlülük göstergesi
              if (_newPasswordController.text.isNotEmpty) ...[
                Row(
                  children: [
                    Expanded(
                      child: LinearProgressIndicator(
                        value: strength,
                        backgroundColor: Colors.grey[800],
                        color: _getPasswordStrengthColor(strength),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _getPasswordStrengthText(strength),
                      style: TextStyle(
                        color: _getPasswordStrengthColor(strength),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'İyi bir şifre en az 8 karakter uzunluğunda olmalı ve büyük/küçük harf, rakam ve özel karakter içermelidir.',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
              const SizedBox(height: 20),
              // Yeni şifre tekrar alanı
              TextFormField(
                controller: _confirmPasswordController,
                decoration: InputDecoration(
                  labelText: 'Yeni Şifre (Tekrar)',
                  labelStyle: const TextStyle(color: Colors.white70),
                  prefixIcon: const Icon(Icons.lock, color: Colors.white60),
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible ? Icons.visibility_off : Icons.visibility,
                      color: Colors.white60,
                    ),
                    onPressed: () {
                      setState(() {
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                      });
                    },
                  ),
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
                style: const TextStyle(color: Colors.white),
                obscureText: !_isConfirmPasswordVisible,
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen yeni şifrenizi tekrar girin.';
                  }
                  if (value != _newPasswordController.text) {
                    return 'Şifreler eşleşmiyor.';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              // Hata ve başarı mesajları
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
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
              if (_successMessage != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.withOpacity(0.5)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Colors.green),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _successMessage!,
                          style: const TextStyle(color: Colors.green),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // Şifre değiştir butonu
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _changePassword,
                  style: ElevatedButton.styleFrom(
                    foregroundColor: Colors.white,
                    backgroundColor: Colors.indigoAccent,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.indigoAccent.withOpacity(0.5),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            strokeWidth: 2,
                          ),
                        )
                      : const Text(
                          'Şifreyi Değiştir',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
              // Şifremi unuttum butonu
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  child: const Text(
                    'Şifremi Unuttum',
                    style: TextStyle(color: Colors.indigoAccent),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
} 