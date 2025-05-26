import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:social_media/services/studentService.dart';
import 'package:line_icons/line_icons.dart';
import 'dart:math' as math;
import 'package:social_media/widgets/error_toast.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui';
import 'package:social_media/theme/app_theme.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _identifierController = TextEditingController();
  String _message = '';
  bool _isSuccess = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));

    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutBack,
    ));

    _animationController.forward();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = '';
      });

      try {
        final studentService = StudentService();
        // POST isteği için kullanıcı adını gönder
        final username = _identifierController.text.trim();
        final response = await studentService.forgotPassword(username);

        setState(() {
          _message =
              response.message ?? 'Bir hata oluştu. Lütfen tekrar deneyin.';
          _isSuccess = response.isSuccess ?? false;
          _isLoading = false;
        });

        if (_isSuccess) {
          _showSuccessDialog();
        } else {
          _showErrorMessage();
        }
      } catch (e) {
        setState(() {
          _message = 'Bağlantı hatası: $e';
          _isSuccess = false;
          _isLoading = false;
        });
        _showErrorMessage();
      }
    }
  }

  void _showErrorMessage() {
    // Hata mesajını göstermek için ScrollController kullan
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_formKey.currentState != null) {
        Scrollable.ensureVisible(
          _formKey.currentContext!,
          alignment: 0.0,
          duration: Duration(milliseconds: 600),
        );
      }
    });
  }

  void _showSuccessDialog() {
    final theme = Theme.of(context);
    final cardColor = theme.cardColor;
    final textColor = theme.colorScheme.onBackground;
    final successColor = theme.colorScheme.primary;
    final buttonColor = theme.colorScheme.secondary;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: successColor,
                size: 60,
              ),
              SizedBox(height: 16),
              Text(
                'Başarılı!',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                  fontSize: 22,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _message,
                style: TextStyle(color: textColor),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 8),
              Text(
                'Giriş sayfasına yönlendiriliyorsunuz...',
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            Center(
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pushReplacementNamed('/login');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: buttonColor,
                  foregroundColor: Colors.white,
                  padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Giriş Sayfasına Dön',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        );
      },
    );

    // 2.5 saniye sonra otomatik olarak login sayfasına yönlendir
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeProvider = Provider.of<ThemeProvider>(context);

    final backgroundColor = theme.scaffoldBackgroundColor;
    final cardColor = theme.cardColor;
    final accentColor = theme.colorScheme.primary;
    final textColor = theme.colorScheme.onBackground;
    final textSecondaryColor =
        theme.textTheme.bodySmall?.color ?? Colors.white70;
    final errorColor = theme.colorScheme.error;
    final linkColor = theme.colorScheme.secondary;
    final buttonColor = theme.colorScheme.primary;
    final buttonTextColor = theme.colorScheme.onPrimary;

    final screenSize = MediaQuery.of(context).size;
    final mediaQuery = MediaQuery.of(context);

    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(),
      child: Scaffold(
        backgroundColor: backgroundColor,
        extendBodyBehindAppBar: true,
        body: Stack(
          children: [
            // Arka plan dekorasyonu
            _buildBackgroundLayer(backgroundColor, accentColor),

            // Ana içerik
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: EdgeInsets.symmetric(horizontal: 24.0),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      SizedBox(height: screenSize.height * 0.02),

                      // Logo
                      FadeTransition(
                        opacity: _fadeAnimation,
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
                      SizedBox(height: screenSize.height * 0.04),

                      // Başlık
                      FadeTransition(
                        opacity: _fadeAnimation,
                        child: Column(
                          children: [
                            Text(
                              'ŞİFREMİ UNUTTUM',
                              style: TextStyle(
                                color: textColor,
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            SizedBox(height: 12),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 15),
                              child: Text(
                                'Şifrenizi sıfırlamak için e-posta adresinizi veya kullanıcı adınızı girin',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  color: textSecondaryColor,
                                  fontSize: 15,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: screenSize.height * 0.04),

                      // Form alanı
                      SlideTransition(
                        position: _slideAnimation,
                        child: FadeTransition(
                          opacity: _fadeAnimation,
                          child: Form(
                            key: _formKey,
                            child: Container(
                              padding: EdgeInsets.all(24),
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
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Hata mesajı
                                  if (_message.isNotEmpty && !_isSuccess)
                                    Container(
                                      margin: EdgeInsets.only(bottom: 16),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: 12, vertical: 10),
                                      decoration: BoxDecoration(
                                        color: errorColor.withOpacity(0.2),
                                        borderRadius: BorderRadius.circular(12),
                                        border: Border.all(
                                          color: errorColor.withOpacity(0.5),
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Icon(
                                            Icons.error_outline,
                                            color: errorColor.withOpacity(0.8),
                                            size: 24,
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              _message,
                                              style: TextStyle(
                                                color: errorColor,
                                                fontSize: 14,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                  // E-posta alanı
                                  TextFormField(
                                    controller: _identifierController,
                                    style: TextStyle(
                                        color: textColor, fontSize: 16),
                                    cursorColor: accentColor,
                                    decoration: InputDecoration(
                                      labelText: 'E-posta veya Kullanıcı Adı',
                                      labelStyle:
                                          TextStyle(color: textSecondaryColor),
                                      prefixIcon: Icon(Icons.person_outline,
                                          color: accentColor, size: 22),
                                      filled: true,
                                      fillColor:
                                          backgroundColor.withOpacity(0.5),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide.none,
                                      ),
                                      enabledBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: textSecondaryColor
                                                .withOpacity(0.1)),
                                      ),
                                      focusedBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: accentColor, width: 1.5),
                                      ),
                                      errorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide: BorderSide(
                                            color: errorColor.withOpacity(0.5)),
                                      ),
                                      focusedErrorBorder: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                        borderSide:
                                            BorderSide(color: errorColor),
                                      ),
                                      errorStyle: TextStyle(color: errorColor),
                                      contentPadding: EdgeInsets.symmetric(
                                          vertical: 16, horizontal: 20),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Lütfen e-posta veya kullanıcı adınızı girin';
                                      }
                                      return null;
                                    },
                                  ),

                                  SizedBox(height: 24),

                                  // Şifre Sıfırlama Butonu
                                  ElevatedButton(
                                    onPressed:
                                        _isLoading ? null : _resetPassword,
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: buttonColor,
                                      foregroundColor: buttonTextColor,
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      padding:
                                          EdgeInsets.symmetric(vertical: 16),
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
                                            'Şifreyi Sıfırla',
                                            style: TextStyle(
                                              fontSize: 16,
                                              fontWeight: FontWeight.bold,
                                              letterSpacing: 1.2,
                                            ),
                                          ),
                                  ),

                                  SizedBox(height: 20),

                                  // Giriş Sayfasına Dön
                                  Center(
                                    child: TextButton.icon(
                                      onPressed: () =>
                                          Navigator.pushReplacementNamed(
                                              context, '/login'),
                                      icon: Icon(Icons.arrow_back_ios_new,
                                          color: linkColor, size: 16),
                                      label: Text(
                                        'Giriş Sayfasına Dön',
                                        style: TextStyle(
                                          color: linkColor,
                                          fontSize: 15,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
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
}
