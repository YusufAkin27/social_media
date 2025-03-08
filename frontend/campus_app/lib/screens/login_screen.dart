import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:social_media/services/authService.dart';
import 'package:social_media/widgets/message_display.dart';
import 'package:social_media/models/login_request_dto.dart';
import 'dart:ui';
import 'package:flutter/gestures.dart';
import 'package:lottie/lottie.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  _LoginScreenState createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  String _message = '';
  bool _isLoading = false;
  bool _showPassword = false;
  final AuthService _authService = AuthService();
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;
  late Animation<double> _scaleAnimation;

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

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.3), end: Offset.zero).animate(
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

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_formKey.currentState?.validate() ?? false) {
      setState(() {
        _isLoading = true;
        _message = '';
      });

      final String username = _usernameController.text;
      final String password = _passwordController.text;

      // IP adresi ve cihaz bilgisi
      String ipAddress = 'campus_app_client';
      String deviceInfo = 'flutter_mobile_app';

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
            _message = 'Giriş başarılı!';
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
            _message = e.toString();
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arka plan dekorasyonu
          Positioned.fill(
            child: _buildBackgroundEffect(),
          ),
          
          // Ana içerik
          SafeArea(
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: Transform.scale(
                          scale: _scaleAnimation.value,
                          child: child,
                        ),
                      ),
                    );
                  },
                  child: _buildLoginForm(screenSize),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildBackgroundEffect() {
    return Stack(
      children: [
        // Ana arka plan
        Container(
          decoration: BoxDecoration(
            color: Colors.black,
            backgroundBlendMode: BlendMode.darken,
            gradient: RadialGradient(
              colors: [
                Colors.black.withOpacity(0.8),
                Colors.black,
              ],
              center: Alignment.topCenter,
              radius: 1.5,
            ),
          ),
        ),
        
        // Bulanıklık efekti
        BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10.0, sigmaY: 10.0),
          child: Container(
            color: Colors.transparent,
          ),
        ),
        
        // Üstte ince parlama efekti
        Positioned(
          top: -100,
          left: 0,
          right: 0,
          child: Container(
            height: 200,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.1),
                  Colors.transparent,
                ],
                radius: 0.8,
              ),
            ),
          ),
        ),
        
        // Alt kısımda hafif bir parlaklık
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
                  Colors.white.withOpacity(0.05),
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

  Widget _buildLoginForm(Size screenSize) {
    return Container(
      width: screenSize.width > 600 ? 500 : double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30.0, horizontal: 24.0),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.5),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.05),
            blurRadius: 20,
            spreadRadius: 1,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Logo Animasyonu
                Hero(
                  tag: 'logo',
                  child: Container(
                    height: 110,
                    width: 110,
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.white.withOpacity(0.15),
                          blurRadius: 15,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                
                const SizedBox(height: 25),
                
                // Hoş geldiniz yazısı
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'HOŞ GELDİNİZ',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                Text(
                  'Kampüs topluluğuna katılmak için giriş yapın',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.7),
                    height: 1.5,
                  ),
                ),
                
                const SizedBox(height: 40),
                
                // Kullanıcı adı alanı
                _buildTextField(
                  controller: _usernameController,
                  labelText: 'Kullanıcı Adı',
                  prefixIcon: CupertinoIcons.person,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Kullanıcı adı gerekli';
                    }
                    return null;
                  },
                ),
                
                const SizedBox(height: 20),
                
                // Şifre alanı - Animasyonlu geçiş efekti
                AnimatedContainer(
                  duration: const Duration(milliseconds: 500),
                  curve: Curves.easeInOut,
                  height: _showPassword ? 80 : 0,
                  child: _showPassword ? _buildTextField(
                    controller: _passwordController,
                    labelText: 'Şifre',
                    prefixIcon: CupertinoIcons.lock,
                    isPassword: true,
                    isPasswordVisible: _isPasswordVisible,
                    onTogglePasswordVisibility: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Şifre gerekli';
                      }
                      if (value.length < 6) {
                        return 'Şifre en az 6 karakter olmalı';
                      }
                      return null;
                    },
                  ) : const SizedBox.shrink(),
                ),
                
                const SizedBox(height: 30),
                
                // Giriş Yap / Devam Et butonu
                _buildGradientButton(
                  onPressed: () {
                    if (!_showPassword) {
                      setState(() {
                        _showPassword = true;
                      });
                    } else {
                      _login();
                    }
                  },
                  label: _showPassword ? 'GİRİŞ YAP' : 'DEVAM ET',
                  isLoading: _isLoading,
                ),
                
                const SizedBox(height: 20),
                
                // Kayıt Ol linki
                RichText(
                  text: TextSpan(
                    text: 'Hesabınız yok mu? ',
                    style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Kayıt Ol',
                        style: const TextStyle(
                          color: Colors.white,
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
                
                const SizedBox(height: 15),
                
                // Şifremi Unuttum linki
                TextButton(
                  onPressed: () {
                    // Şifre sıfırlama ekranına yönlendirme
                    Navigator.pushNamed(context, '/forgot-password');
                  },
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Şifremi Unuttum',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 13,
                    ),
                  ),
                ),
                
                const SizedBox(height: 30),
                
                // Mesaj Gösterimi
                if (_message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 10),
                    child: MessageDisplay(
                      isSuccess: _message == 'Giriş başarılı!',
                      message: _message,
                      maxCharacters: 100,
                    ),
                  ),
                
                const SizedBox(height: 20),
                
                // Alternatif giriş yöntemleri
                _buildAlternativeLoginMethods(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePasswordVisibility,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      style: const TextStyle(color: Colors.white, fontSize: 16),
      cursorColor: Colors.white,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
        prefixIcon: Icon(prefixIcon, color: Colors.white.withOpacity(0.7)),
        suffixIcon: isPassword ? IconButton(
          icon: Icon(
            isPasswordVisible ? CupertinoIcons.eye : CupertinoIcons.eye_slash,
            color: Colors.white.withOpacity(0.7),
            size: 20,
          ),
          onPressed: onTogglePasswordVisibility,
        ) : null,
        filled: true,
        fillColor: Colors.white.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.white, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: const TextStyle(color: Colors.redAccent),
        contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      validator: validator,
    );
  }
  
  Widget _buildGradientButton({
    required VoidCallback onPressed,
    required String label,
    bool isLoading = false,
  }) {
    return Container(
      width: double.infinity,
      height: 55,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: LinearGradient(
          colors: [
            Colors.white.withOpacity(0.9),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withOpacity(0.1),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: isLoading
            ? const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                ),
              )
            : Text(
                label,
                style: const TextStyle(
                  color: Colors.black,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }
  
  Widget _buildAlternativeLoginMethods() {
    return Column(
      children: [
        Text(
          'VEYA',
          style: TextStyle(
            color: Colors.white.withOpacity(0.5),
            fontSize: 12,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildSocialLoginButton(
              icon: Icons.g_mobiledata_rounded,
              color: Colors.red.shade400,
              onTap: () {
                // Google ile giriş işlemi
                setState(() {
                  _message = 'Bu özellik yakında kullanıma açılacak.';
                });
              },
            ),
            const SizedBox(width: 20),
            _buildSocialLoginButton(
              icon: Icons.apple_rounded,
              color: Colors.white,
              onTap: () {
                // Apple ile giriş işlemi
                setState(() {
                  _message = 'Bu özellik yakında kullanıma açılacak.';
                });
              },
            ),
            const SizedBox(width: 20),
            _buildSocialLoginButton(
              icon: Icons.facebook_rounded,
              color: Colors.blue.shade600,
              onTap: () {
                // Facebook ile giriş işlemi
                setState(() {
                  _message = 'Bu özellik yakında kullanıma açılacak.';
                });
              },
            ),
          ],
        ),
      ],
    );
  }
  
  Widget _buildSocialLoginButton({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.black,
          border: Border.all(color: Colors.white.withOpacity(0.2)),
        ),
        child: Icon(
          icon,
          color: color,
          size: 30,
        ),
      ),
    );
  }
}