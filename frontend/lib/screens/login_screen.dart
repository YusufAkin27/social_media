import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:social_media/services/authService.dart';
import 'package:social_media/widgets/error_toast.dart';
import 'package:social_media/models/login_request_dto.dart';
import 'package:social_media/theme/app_theme.dart';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:lottie/lottie.dart';
import 'dart:math' as math;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  bool _showPassword = false;
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.65, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.3, 0.8, curve: Curves.easeOut),
      ),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  void _showErrorToast(String message) {
    _overlayEntry?.remove();
    _overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 0,
        right: 0,
        child: ErrorToast(
          title: 'Giriş Hatası',
          message: message,
          duration: const Duration(seconds: 3),
          maxLength: 60,
          onDismiss: () {
            _overlayEntry?.remove();
            _overlayEntry = null;
          },
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  @override
  void dispose() {
    _overlayEntry?.remove();
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _continueToPassword() {
    if (_usernameController.text.isNotEmpty) {
      setState(() {
        _showPassword = true;
      });
    } else {
      _showErrorToast('Lütfen kullanıcı adınızı giriniz');
    }
  }

  Future<void> _login() async {
    if (!_showPassword) {
      _continueToPassword();
      return;
    }

    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
      });

      final String username = _usernameController.text;
      final String password = _passwordController.text;

      // Otomatik olarak cihaz bilgisi ve IP adresi al
      String ipAddress = await getIpAddress();
      String deviceInfo = await getDeviceInfo();

      final loginRequest = LoginRequestDTO(
        username: username,
        password: password,
        ipAddress: ipAddress,
        deviceInfo: deviceInfo,
      );

      try {
        await _authService.login(loginRequest);

        if (mounted) {
          setState(() {
            _isLoading = false;
          });

          // Ana sayfaya geçiş
          Future.delayed(const Duration(milliseconds: 800), () {
            if (mounted) {
              Navigator.pushReplacementNamed(context, '/home');
            }
          });
        }
      } catch (e) {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
          String errorMessage = e.toString();
          if (errorMessage.contains('Exception:')) {
            errorMessage = errorMessage.split('Exception:')[1].trim();
          }
          _showErrorToast(errorMessage);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
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
    final buttonColor = isDarkMode
        ? AppColors.buttonBackground
        : AppColors.lightButtonBackground;
    final buttonTextColor =
        isDarkMode ? AppColors.buttonText : AppColors.lightButtonText;
    final linkColor = isDarkMode ? AppColors.link : AppColors.lightLink;
    final errorColor = isDarkMode ? AppColors.error : AppColors.lightError;
    final inputBackgroundColor = isDarkMode
        ? AppColors.inputBackground
        : AppColors.lightBackground.withOpacity(0.8);

    final screenSize = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).viewPadding;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      body: GestureDetector(
        onTap: () => FocusScope.of(context).unfocus(),
        child: Stack(
          children: [
            // Arkaplan efekti
            _buildBackgroundLayer(backgroundColor, accentColor),

            // Ana içerik
            SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          screenSize.height - padding.top - padding.bottom,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        SizedBox(height: screenSize.height * 0.05),

                        // Logo
                        _buildAnimatedLogo(accentColor, cardColor),
                        SizedBox(height: screenSize.height * 0.04),

                        // Hoş geldiniz metni
                        FadeTransition(
                          opacity: _fadeAnimation,
                          child: Column(
                            children: [
                              Text(
                                'HOŞ GELDİNİZ',
                                style: TextStyle(
                                  color: textColor,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1.2,
                                ),
                              ),
                              SizedBox(height: 12),
                              Text(
                                'Kampüs topluluğuna katılmak için giriş yapın',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: secondaryTextColor,
                                  fontSize: 15,
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(height: screenSize.height * 0.05),

                        // Giriş formu
                        _buildLoginForm(
                          textColor,
                          secondaryTextColor,
                          accentColor,
                          buttonColor,
                          buttonTextColor,
                          cardColor,
                          errorColor,
                          inputBackgroundColor,
                        ),
                        SizedBox(height: 24),

                        // Hesap oluşturma & Şifre unutma linkleri
                        _buildActionLinks(secondaryTextColor, linkColor),
                        SizedBox(height: 32),

                        // Sosyal medya ile giriş
                        _buildSocialLoginSection(secondaryTextColor, cardColor,
                            errorColor, textColor, accentColor),
                        SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBackgroundLayer(Color backgroundColor, Color accentColor) {
    return Stack(
      children: [
        // Gradient arkaplan
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                backgroundColor.withOpacity(0.9),
                backgroundColor,
              ],
            ),
          ),
        ),

        // Üst kısım ışık efekti
        Positioned(
          top: -100,
          left: 0,
          right: 0,
          child: Container(
            height: 250,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  accentColor.withOpacity(0.15),
                  Colors.transparent,
                ],
                radius: 0.8,
              ),
            ),
          ),
        ),

        // Alt kısım ışık efekti
        Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: Container(
            height: 150,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  accentColor.withOpacity(0.05),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAnimatedLogo(Color accentColor, Color cardColor) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: Hero(
          tag: 'logo',
          child: Container(
            height: 120,
            width: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.4),
                  blurRadius: 20,
                  spreadRadius: 2,
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
      ),
    );
  }

  Widget _buildLoginForm(
    Color textColor,
    Color secondaryTextColor,
    Color accentColor,
    Color buttonColor,
    Color buttonTextColor,
    Color cardColor,
    Color errorColor,
    Color inputBackgroundColor,
  ) {
    return SlideTransition(
      position: _slideAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: Form(
          key: _formKey,
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Kullanıcı adı alanı
                _buildInputField(
                  controller: _usernameController,
                  labelText: 'Kullanıcı Adı',
                  icon: Icons.person_outline,
                  textColor: textColor,
                  hintColor: secondaryTextColor,
                  accentColor: accentColor,
                  backgroundColor: inputBackgroundColor,
                  errorColor: errorColor,
                ),
                SizedBox(height: 20),

                // Şifre alanı
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  height: _showPassword ? 70 : 0,
                  child: AnimatedOpacity(
                    duration: const Duration(milliseconds: 500),
                    opacity: _showPassword ? 1.0 : 0.0,
                    child: _showPassword
                        ? _buildInputField(
                            controller: _passwordController,
                            labelText: 'Şifre',
                            icon: Icons.lock_outline,
                            isPassword: true,
                            isPasswordVisible: _isPasswordVisible,
                            onTogglePasswordVisibility: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                            textColor: textColor,
                            hintColor: secondaryTextColor,
                            accentColor: accentColor,
                            backgroundColor: inputBackgroundColor,
                            errorColor: errorColor,
                          )
                        : SizedBox.shrink(),
                  ),
                ),
                SizedBox(height: 24),

                // Giriş butonu
                SizedBox(
                  width: MediaQuery.of(context).size.width * 0.8,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: buttonColor,
                      foregroundColor: buttonTextColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 4,
                    ),
                    child: _isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.5,
                              color: buttonTextColor,
                            ),
                          )
                        : Text(
                            _showPassword ? 'GİRİŞ YAP' : 'DEVAM ET',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.2,
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

  Widget _buildInputField({
    required TextEditingController controller,
    required String labelText,
    required IconData icon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePasswordVisibility,
    required Color textColor,
    required Color hintColor,
    required Color accentColor,
    required Color backgroundColor,
    required Color errorColor,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      style: TextStyle(color: textColor, fontSize: 16),
      cursorColor: accentColor,
      validator: (value) {
        if (value == null || value.isEmpty) {
          return isPassword ? 'Şifre gerekli' : 'Kullanıcı adı gerekli';
        }
        if (isPassword && value.length < 6) {
          return 'Şifre en az 6 karakter olmalı';
        }
        return null;
      },
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: hintColor),
        hintStyle: TextStyle(color: hintColor.withOpacity(0.7)),
        prefixIcon: Icon(icon, color: accentColor, size: 22),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: accentColor,
                  size: 22,
                ),
                splashRadius: 24,
                onPressed: onTogglePasswordVisibility,
              )
            : null,
        filled: true,
        fillColor: backgroundColor.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: hintColor.withOpacity(0.1)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor.withOpacity(0.5)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: errorColor),
        ),
        errorStyle: TextStyle(color: errorColor),
        contentPadding: EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
    );
  }

  Widget _buildActionLinks(Color secondaryTextColor, Color linkColor) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              text: 'Hesabınız yok mu? ',
              style: TextStyle(
                color: secondaryTextColor,
                fontSize: 15,
              ),
              children: [
                TextSpan(
                  text: 'Kayıt Ol',
                  style: TextStyle(
                    color: linkColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  recognizer: TapGestureRecognizer()
                    ..onTap = () {
                      Navigator.pushNamed(context, '/register');
                    },
                ),
              ],
            ),
          ),
          SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.pushNamed(context, '/forgot-password'),
            style: TextButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 4),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              'Şifremi Unuttum',
              style: TextStyle(
                color: linkColor.withOpacity(0.8),
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSocialLoginSection(
    Color secondaryTextColor,
    Color cardColor,
    Color errorColor,
    Color textColor,
    Color accentColor,
  ) {
    return FadeTransition(
      opacity: _fadeAnimation,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Divider(
                  color: secondaryTextColor.withOpacity(0.3),
                  thickness: 1,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'VEYA',
                  style: TextStyle(
                    color: secondaryTextColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    letterSpacing: 1,
                  ),
                ),
              ),
              Expanded(
                child: Divider(
                  color: secondaryTextColor.withOpacity(0.3),
                  thickness: 1,
                ),
              ),
            ],
          ),
          SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSocialButton(
                icon: Icons.g_mobiledata_rounded,
                color: errorColor,
                cardColor: cardColor,
              ),
              SizedBox(width: 20),
              _buildSocialButton(
                icon: Icons.apple_rounded,
                color: textColor,
                cardColor: cardColor,
              ),
              SizedBox(width: 20),
              _buildSocialButton(
                icon: Icons.facebook_rounded,
                color: accentColor,
                cardColor: cardColor,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSocialButton({
    required IconData icon,
    required Color color,
    required Color cardColor,
  }) {
    return InkWell(
      onTap: () {
        _showErrorToast('Bu özellik yakında kullanıma açılacak.');
      },
      customBorder: CircleBorder(),
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: cardColor,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            icon,
            color: color,
            size: 28,
          ),
        ),
      ),
    );
  }

  Future<String> getDeviceInfo() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return 'Android ${androidInfo.model} (${androidInfo.id})';
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return 'iOS ${iosInfo.utsname.machine} (${iosInfo.identifierForVendor})';
    }
    return 'Unknown Device';
  }

  Future<String> getIpAddress() async {
    try {
      final response =
          await http.get(Uri.parse('https://api64.ipify.org?format=json'));
      if (response.statusCode == 200) {
        return json.decode(response.body)['ip'];
      }
    } catch (e) {
      // Hata durumunda local IP döndür
      for (var interface in await NetworkInterface.list()) {
        for (var addr in interface.addresses) {
          if (addr.type == InternetAddressType.IPv4 && !addr.isLoopback) {
            return addr.address;
          }
        }
      }
    }
    return 'Unknown IP';
  }
}
