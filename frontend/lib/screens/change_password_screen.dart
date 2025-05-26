import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:social_media/theme/app_theme.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({Key? key}) : super(key: key);

  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

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
    final hasSpecialChars =
        password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

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
  Color _getPasswordStrengthColor(double strength, ThemeData theme) {
    if (strength < 0.3) return theme.colorScheme.error;
    if (strength < 0.7) return theme.colorScheme.tertiary;
    return theme.colorScheme.primary;
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
        Uri.parse('http://192.168.89.61:8080/v1/api/auth/change-password'),
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
          _errorMessage = responseData['message'] ??
              'Şifre değiştirme sırasında bir hata oluştu.';
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
    final themeProvider = Provider.of<ThemeProvider>(context);
    final theme = themeProvider.currentTheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor:
            theme.appBarTheme.backgroundColor ?? theme.scaffoldBackgroundColor,
        title: Text(
          'Şifre Değiştir',
          style: TextStyle(
            color: theme.colorScheme.onSurface,
            letterSpacing: 0.5,
            fontWeight: FontWeight.w500,
            fontSize: 18,
          ),
        ),
        elevation: 0,
        iconTheme: IconThemeData(color: theme.colorScheme.onSurface),
        leading: Container(
          margin: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
            shape: BoxShape.circle,
          ),
          child: IconButton(
            icon: Icon(Icons.arrow_back_ios_new, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              theme.scaffoldBackgroundColor,
              theme.colorScheme.surface,
            ],
            stops: const [0.0, 1.0],
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        color: theme.colorScheme.primary,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Şifrenizi değiştirmek için önce mevcut şifrenizi doğrulamanız gerekiyor.',
                          style: TextStyle(
                            color: theme.colorScheme.onSurface.withOpacity(0.8),
                            fontSize: 14,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Mevcut şifre alanı
                _buildPasswordField(
                  controller: _currentPasswordController,
                  labelText: 'Mevcut Şifre',
                  prefixIcon: Icons.lock_outline_rounded,
                  isVisible: _isCurrentPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() {
                      _isCurrentPasswordVisible = !_isCurrentPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen mevcut şifrenizi girin.';
                    }
                    return null;
                  },
                  theme: theme,
                ),

                const SizedBox(height: 20),

                // Yeni şifre alanı
                _buildPasswordField(
                  controller: _newPasswordController,
                  labelText: 'Yeni Şifre',
                  prefixIcon: Icons.lock_rounded,
                  isVisible: _isNewPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() {
                      _isNewPasswordVisible = !_isNewPasswordVisible;
                    });
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
                  onChanged: (value) {
                    setState(() {});
                  },
                  theme: theme,
                ),

                const SizedBox(height: 12),

                // Şifre güçlülük göstergesi
                if (_newPasswordController.text.isNotEmpty) ...[
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: strength,
                            backgroundColor: theme.colorScheme.surfaceVariant,
                            color: _getPasswordStrengthColor(strength, theme),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        _getPasswordStrengthText(strength),
                        style: TextStyle(
                          color: _getPasswordStrengthColor(strength, theme),
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'İyi bir şifre en az 8 karakter uzunluğunda olmalı ve büyük/küçük harf, rakam ve özel karakter içermelidir.',
                    style: TextStyle(
                      color: theme.colorScheme.onSurface.withOpacity(0.6),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],

                const SizedBox(height: 20),

                // Yeni şifre tekrar alanı
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  labelText: 'Yeni Şifre (Tekrar)',
                  prefixIcon: Icons.lock_rounded,
                  isVisible: _isConfirmPasswordVisible,
                  onVisibilityToggle: () {
                    setState(() {
                      _isConfirmPasswordVisible = !_isConfirmPasswordVisible;
                    });
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Lütfen yeni şifrenizi tekrar girin.';
                    }
                    if (value != _newPasswordController.text) {
                      return 'Şifreler eşleşmiyor.';
                    }
                    return null;
                  },
                  theme: theme,
                ),

                const SizedBox(height: 24),

                // Hata ve başarı mesajları
                if (_errorMessage != null)
                  _buildMessageBox(
                    message: _errorMessage!,
                    icon: Icons.error_outline_rounded,
                    iconColor: theme.colorScheme.error,
                    backgroundColor: theme.colorScheme.error.withOpacity(0.1),
                    borderColor: theme.colorScheme.error.withOpacity(0.3),
                    textColor: theme.colorScheme.error,
                  ),

                if (_successMessage != null)
                  _buildMessageBox(
                    message: _successMessage!,
                    icon: Icons.check_circle_outline_rounded,
                    iconColor: theme.colorScheme.tertiary,
                    backgroundColor:
                        theme.colorScheme.tertiary.withOpacity(0.1),
                    borderColor: theme.colorScheme.tertiary.withOpacity(0.3),
                    textColor: theme.colorScheme.tertiary,
                  ),

                const SizedBox(height: 32),

                // Şifre değiştir butonu
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _changePassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.primary,
                      foregroundColor: theme.colorScheme.onPrimary,
                      disabledBackgroundColor:
                          theme.colorScheme.primary.withOpacity(0.6),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isLoading
                        ? SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  theme.colorScheme.onPrimary),
                              strokeWidth: 2,
                            ),
                          )
                        : Text(
                            'Şifreyi Değiştir',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                              letterSpacing: 0.5,
                            ),
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
                    style: TextButton.styleFrom(
                      foregroundColor: theme.colorScheme.primary,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Şifremi Unuttum',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
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

  // Şifre alanı widget'ı
  Widget _buildPasswordField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    required bool isVisible,
    required Function() onVisibilityToggle,
    required String? Function(String?) validator,
    Function(String)? onChanged,
    required ThemeData theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: TextFormField(
        controller: controller,
        style: TextStyle(
          color: theme.colorScheme.onSurface,
          fontSize: 16,
        ),
        decoration: InputDecoration(
          labelText: labelText,
          labelStyle: TextStyle(
            color: theme.colorScheme.onSurface.withOpacity(0.7),
            fontSize: 15,
          ),
          prefixIcon: Icon(
            prefixIcon,
            color: theme.colorScheme.primary,
            size: 20,
          ),
          suffixIcon: IconButton(
            icon: Icon(
              isVisible
                  ? Icons.visibility_off_rounded
                  : Icons.visibility_rounded,
              color: theme.colorScheme.onSurface.withOpacity(0.6),
              size: 20,
            ),
            onPressed: onVisibilityToggle,
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.primary.withOpacity(0.6),
              width: 1,
            ),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.error,
              width: 1,
            ),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: theme.colorScheme.error,
              width: 1.5,
            ),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          filled: true,
          fillColor: Colors.transparent,
          errorStyle: TextStyle(
            color: theme.colorScheme.error,
            fontSize: 12,
          ),
        ),
        obscureText: !isVisible,
        validator: validator,
        onChanged: onChanged,
      ),
    );
  }

  // Mesaj kutusu widget'ı
  Widget _buildMessageBox({
    required String message,
    required IconData icon,
    required Color iconColor,
    required Color backgroundColor,
    required Color borderColor,
    required Color textColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: iconColor, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
