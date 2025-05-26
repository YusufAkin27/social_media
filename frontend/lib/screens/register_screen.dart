import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:social_media/main.dart';
import 'package:social_media/enums/department.dart';
import 'package:social_media/enums/grade.dart';
import 'package:social_media/enums/faculty.dart';
import 'package:social_media/models/create_student_request.dart';
import 'package:social_media/services/studentService.dart';
import 'package:social_media/widgets/error_toast.dart';
import 'package:social_media/theme/app_theme.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthDateController = TextEditingController();

  // FocusNode'lar
  final _nameFocus = FocusNode();
  final _surnameFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _usernameFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _birthDateFocus = FocusNode();

  Department? _selectedDepartment;
  Faculty? _selectedFaculty;
  Grade? _selectedGrade;
  bool _gender = true; // true: Erkek, false: Kadın
  int _currentStep = 0;
  bool _obscurePassword = true; // Şifre görünürlüğü için
  final StudentService _studentService = StudentService();
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

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOut),
      ),
    );

    _slideAnimation =
        Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
      CurvedAnimation(
        parent: _animationController,
        curve: const Interval(0.2, 0.7, curve: Curves.easeOut),
      ),
    );

    _animationController.forward();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _surnameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _birthDateController.dispose();

    // FocusNode'ları dispose et
    _nameFocus.dispose();
    _surnameFocus.dispose();
    _emailFocus.dispose();
    _phoneFocus.dispose();
    _usernameFocus.dispose();
    _passwordFocus.dispose();
    _birthDateFocus.dispose();

    _animationController.dispose();
    super.dispose();
  }

  void _nextStep() {
    if (_formKey.currentState!.validate()) {
      setState(() {
        if (_currentStep < 2) {
          _currentStep++;
          _animationController.reset();
          _animationController.forward();
        }
      });
    }
  }

  void _previousStep() {
    setState(() {
      if (_currentStep > 0) {
        _currentStep--;
        _animationController.reset();
        _animationController.forward();
      }
    });
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
        _message = '';
      });

      final createStudentRequest = CreateStudentRequest(
        firstName: _nameController.text,
        lastName: _surnameController.text,
        username: _usernameController.text,
        password: _passwordController.text,
        email: _emailController.text,
        mobilePhone: _phoneController.text.replaceAll(' ', ''),
        department: _selectedDepartment ?? Department.DEFAULT,
        faculty: _selectedFaculty ?? Faculty.DEFAULT,
        grade: _selectedGrade ?? Grade.DEFAULT,
        birthDate:
            DateTime.tryParse(_birthDateController.text) ?? DateTime.now(),
        gender: _gender,
      );

      try {
        // API'den yanıt al
        final response = await _studentService.signUp(createStudentRequest);

        setState(() {
          _isLoading = false;
          _isSuccess = response.isSuccess ?? false;
          _message = response.message ?? '';
        });

        if (_isSuccess) {
          // Başarılı kayıt durumunda login sayfasına yönlendir
          Navigator.pushReplacementNamed(context, '/login');
        } else {
          // Hata durumunda ErrorToast ile hata mesajını göster
          if (_message.isEmpty) {
            _message = 'Kayıt işlemi başarısız oldu. Lütfen tekrar deneyin.';
          }

          // ErrorToast ile hata göster
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: ErrorToast(
                message: _message,
                duration: const Duration(seconds: 4),
                title: 'Kayıt Hatası',
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );

          // Kaydırma için ekranın üstüne doğru git
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
      } catch (e) {
        // Beklenmeyen bir hata durumunda
        print('Beklenmeyen kayıt hatası: $e');
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _message =
              'Beklenmeyen bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
        });

        // Hata durumunda ErrorToast ile hata mesajını göster
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: ErrorToast(
              message: _message,
              duration: const Duration(seconds: 4),
              title: 'Sistem Hatası',
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  // Başarılı kayıt diyaloğu
  void _showSuccessDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    final backgroundColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Column(
            children: [
              Icon(
                Icons.check_circle_outline,
                color: accentColor,
                size: 60,
              ),
              SizedBox(height: 16),
              Text(
                'Kayıt Başarılı',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                _message.isNotEmpty
                    ? _message
                    : 'Hesabınız başarıyla oluşturuldu!',
                textAlign: TextAlign.center,
                style: TextStyle(color: textColor),
              ),
              SizedBox(height: 8),
              Text(
                'Giriş sayfasına yönlendiriliyorsunuz...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: textColor.withOpacity(0.7),
                  fontSize: 14,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: Text(
                'Hemen Giriş Yap',
                style: TextStyle(
                  color: accentColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        );
      },
    );

    // 2 saniye sonra otomatik olarak login sayfasına yönlendir
    Future.delayed(const Duration(milliseconds: 2500), () {
      if (mounted) {
        Navigator.of(context).popUntil((route) => route.isFirst);
        Navigator.pushReplacementNamed(context, '/login');
      }
    });
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;

    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final primaryText =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;
    final cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now()
          .subtract(const Duration(days: 365 * 18)), // 18 yaş varsayılan
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: ColorScheme.dark(
              primary: accentColor,
              onPrimary: Colors.white,
              surface: cardColor,
              onSurface: primaryText,
            ),
            dialogBackgroundColor: cardColor,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text =
            "${picked.toLocal()}".split(' ')[0]; // YYYY-MM-DD formatında
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);
    final isDarkMode = themeProvider.isDarkMode;

    // Tema değişimine göre renkleri ayarla
    final backgroundColor =
        isDarkMode ? AppColors.background : AppColors.lightBackground;
    final cardColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;
    final textSecondaryColor =
        isDarkMode ? AppColors.secondaryText : AppColors.lightSecondaryText;
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;

    final screenSize = MediaQuery.of(context).size;
    final mediaQuery = MediaQuery.of(context);
    final viewPadding = mediaQuery.viewPadding;

    return Scaffold(
      backgroundColor: backgroundColor,
      extendBodyBehindAppBar: true,
      extendBody: true,
      resizeToAvoidBottomInset: true,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Arka plan efekti
          _buildBackgroundEffect(isDarkMode, backgroundColor, accentColor),

          // Ana içerik
          SafeArea(
            bottom: true,
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: EdgeInsets.only(
                left: screenSize.width * 0.05,
                right: screenSize.width * 0.05,
                bottom: MediaQuery.of(context).viewInsets.bottom + 20,
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight:
                      screenSize.height - viewPadding.top - viewPadding.bottom,
                ),
                child: AnimatedBuilder(
                  animation: _animationController,
                  builder: (context, child) {
                    return FadeTransition(
                      opacity: _fadeAnimation,
                      child: SlideTransition(
                        position: _slideAnimation,
                        child: child,
                      ),
                    );
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      SizedBox(height: screenSize.height * 0.02),
                      _buildRegisterHeader(screenSize, textColor, cardColor,
                          accentColor, backgroundColor, textSecondaryColor),
                      SizedBox(height: screenSize.height * 0.02),
                      _buildStepContent(screenSize, cardColor, accentColor,
                          textColor, textSecondaryColor, backgroundColor),
                      SizedBox(height: screenSize.height * 0.04),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackgroundEffect(
      bool isDarkMode, Color backgroundColor, Color accentColor) {
    return Stack(
      children: [
        // Ana arka plan
        Container(
          decoration: BoxDecoration(
            color: backgroundColor,
            backgroundBlendMode: BlendMode.darken,
            gradient: RadialGradient(
              colors: [
                backgroundColor.withOpacity(0.8),
                backgroundColor,
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
                  accentColor.withOpacity(0.1),
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

  Widget _buildRegisterHeader(Size screenSize, Color textColor, Color cardColor,
      Color accentColor, Color backgroundColor, Color textSecondaryColor) {
    return Column(
      children: [
        // Logo veya İkon
        Hero(
          tag: 'logo',
          child: Container(
            height: screenSize.width * 0.35,
            width: screenSize.width * 0.35,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: cardColor,
              boxShadow: [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 25,
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

        SizedBox(height: math.min(20, screenSize.height * 0.025)),

        // Başlık
        ShaderMask(
          shaderCallback: (Rect bounds) {
            return LinearGradient(
              colors: [textColor, textColor.withOpacity(0.8)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ).createShader(bounds);
          },
          child: Text(
            'ÜYE OL',
            style: TextStyle(
              fontSize: math.min(28, screenSize.width * 0.065),
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
              color: textColor,
            ),
          ),
        ),

        SizedBox(height: screenSize.height * 0.015),

        // Adım göstergesi
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
              3,
              (index) => _buildStepIndicator(index, textColor, accentColor,
                  backgroundColor, textSecondaryColor)),
        ),

        SizedBox(height: screenSize.height * 0.01),

        // Adım başlığı
        Text(
          _getStepTitle(),
          style: TextStyle(
            fontSize: math.min(16, screenSize.width * 0.04),
            color: textColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildStepContent(Size screenSize, Color cardColor, Color accentColor,
      Color textColor, Color textSecondaryColor, Color backgroundColor) {
    return Container(
      width: screenSize.width,
      padding: EdgeInsets.symmetric(
          vertical: math.min(25.0, screenSize.height * 0.035),
          horizontal: math.min(20.0, screenSize.width * 0.05)),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: accentColor.withOpacity(0.1), width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.2),
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
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Mesaj gösterimi
                if (_message.isNotEmpty && !_isSuccess)
                  Container(
                    margin: EdgeInsets.only(bottom: 16),
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.red.shade700.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.shade300.withOpacity(0.5),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.error_outline,
                          color: Colors.red.shade300,
                          size: 24,
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _message,
                            style: TextStyle(
                              color: Colors.red.shade100,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Form içeriği - Adıma göre farklı içerik gösterimi
                _currentStep == 0
                    ? _buildPersonalInfoStep(
                        textColor, textSecondaryColor, accentColor)
                    : _currentStep == 1
                        ? _buildAccountInfoStep(textColor, textSecondaryColor,
                            accentColor, cardColor, backgroundColor)
                        : _buildEducationInfoStep(
                            textColor, textSecondaryColor, accentColor),

                SizedBox(height: math.min(25, screenSize.height * 0.035)),

                // Navigasyon butonları
                _buildNavigationButtons(
                    textColor, accentColor, textSecondaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getStepTitle() {
    switch (_currentStep) {
      case 0:
        return 'Kişisel Bilgiler';
      case 1:
        return 'Hesap Bilgileri';
      case 2:
        return 'Eğitim Bilgileri';
      default:
        return '';
    }
  }

  Widget _buildStepIndicator(int step, Color textColor, Color accentColor,
      Color backgroundColor, Color textSecondaryColor) {
    bool isActive = _currentStep >= step;
    bool isCurrent = _currentStep == step;
    final screenSize = MediaQuery.of(context).size;
    final indicatorSize = math.min(
        isCurrent ? 35.0 : 30.0, screenSize.width * (isCurrent ? 0.085 : 0.07));

    return Container(
      margin: EdgeInsets.symmetric(
          horizontal: math.min(8, screenSize.width * 0.02)),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: indicatorSize,
            height: indicatorSize,
            decoration: BoxDecoration(
              color: isActive ? textColor : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color:
                    isActive ? textColor : textSecondaryColor.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: accentColor.withOpacity(0.2),
                        blurRadius: 10,
                        spreadRadius: 2,
                      )
                    ]
                  : null,
            ),
            child: Center(
              child: Text(
                '${step + 1}',
                style: TextStyle(
                  color: isActive ? backgroundColor : textSecondaryColor,
                  fontWeight: FontWeight.bold,
                  fontSize: math.min(14, screenSize.width * 0.035),
                ),
              ),
            ),
          ),
          if (step < 2)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: math.min(20, screenSize.width * 0.05),
              height: 2,
              color: isActive
                  ? textColor.withOpacity(0.7)
                  : textSecondaryColor.withOpacity(0.2),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep(
      Color textColor, Color textSecondaryColor, Color accentColor) {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          labelText: 'Ad',
          prefixIcon: CupertinoIcons.person,
          textColor: textColor,
          textSecondaryColor: textSecondaryColor,
          accentColor: accentColor,
          focusNode: _nameFocus,
          onEditingComplete: () =>
              FocusScope.of(context).requestFocus(_surnameFocus),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen adınızı girin';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _surnameController,
          labelText: 'Soyad',
          prefixIcon: CupertinoIcons.person_2,
          textColor: textColor,
          textSecondaryColor: textSecondaryColor,
          accentColor: accentColor,
          focusNode: _surnameFocus,
          onEditingComplete: () =>
              FocusScope.of(context).requestFocus(_emailFocus),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen soyadınızı girin';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _emailController,
          labelText: 'E-posta',
          prefixIcon: CupertinoIcons.mail,
          keyboardType: TextInputType.emailAddress,
          textColor: textColor,
          textSecondaryColor: textSecondaryColor,
          accentColor: accentColor,
          focusNode: _emailFocus,
          onEditingComplete: () =>
              FocusScope.of(context).requestFocus(_phoneFocus),
          validator: (value) {
            if (value == null ||
                value.isEmpty ||
                value.length < 5 ||
                !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
              return 'Lütfen geçerli bir e-posta adresi girin';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _phoneController,
          labelText: 'Telefon Numarası',
          prefixIcon: CupertinoIcons.phone,
          keyboardType: TextInputType.phone,
          maxLength: 12,
          textColor: textColor,
          textSecondaryColor: textSecondaryColor,
          accentColor: accentColor,
          focusNode: _phoneFocus,
          textInputAction: TextInputAction.done,
          onEditingComplete: _nextStep,
          onChanged: _formatPhoneNumber,
          validator: (value) {
            if (value == null || value.isEmpty || value.length < 10) {
              return 'Lütfen geçerli bir telefon numarası girin';
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildAccountInfoStep(Color textColor, Color textSecondaryColor,
      Color accentColor, Color cardColor, Color backgroundColor) {
    return Column(
      children: [
        _buildTextField(
          controller: _usernameController,
          labelText: 'Kullanıcı Adı',
          prefixIcon: CupertinoIcons.at,
          textColor: textColor,
          textSecondaryColor: textSecondaryColor,
          accentColor: accentColor,
          focusNode: _usernameFocus,
          onEditingComplete: () =>
              FocusScope.of(context).requestFocus(_passwordFocus),
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen kullanıcı adınızı girin';
            }
            return null;
          },
        ),
        const SizedBox(height: 16),
        _buildTextField(
          controller: _passwordController,
          labelText: 'Şifre',
          prefixIcon: CupertinoIcons.lock,
          isPassword: true,
          isPasswordVisible: !_obscurePassword,
          textColor: textColor,
          textSecondaryColor: textSecondaryColor,
          accentColor: accentColor,
          focusNode: _passwordFocus,
          textInputAction: TextInputAction.done,
          onEditingComplete: _nextStep,
          onTogglePasswordVisibility: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Lütfen şifrenizi girin';
            }
            if (value.length < 6) {
              return 'Şifre en az 6 karakter olmalı';
            }
            return null;
          },
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: backgroundColor.withOpacity(0.5),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: accentColor.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Güçlü bir şifre için:',
                style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildPasswordTip(
                  'En az 8 karakter kullanın', textSecondaryColor),
              _buildPasswordTip(
                  'Büyük ve küçük harfler kullanın', textSecondaryColor),
              _buildPasswordTip(
                  'Rakam ve özel karakterler ekleyin', textSecondaryColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTip(String tip, Color textSecondaryColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: textSecondaryColor,
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            tip,
            style: TextStyle(
              color: textSecondaryColor,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEducationInfoStep(
      Color textColor, Color textSecondaryColor, Color accentColor) {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor =
        isDarkMode ? AppColors.background : AppColors.lightBackground;

    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            children: [
              _buildDropdown<Faculty>(
                value: _selectedFaculty,
                labelText: 'Fakülte',
                items: Faculty.values.map((faculty) {
                  return DropdownMenuItem<Faculty>(
                    value: faculty,
                    child: Text(faculty.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedFaculty = value;
                    _selectedDepartment = null;
                  });
                },
                textColor: textColor,
                textSecondaryColor: textSecondaryColor,
                accentColor: accentColor,
                backgroundColor: backgroundColor,
                validator: (value) {
                  if (value == null) {
                    return 'Lütfen fakültenizi seçin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown<Department>(
                value: _selectedDepartment,
                labelText: 'Bölüm',
                items: _selectedFaculty != null
                    ? _selectedFaculty!.departments.map((department) {
                        return DropdownMenuItem<Department>(
                          value: department,
                          child: Text(department.displayName),
                        );
                      }).toList()
                    : [],
                onChanged: (value) {
                  setState(() {
                    _selectedDepartment = value;
                  });
                },
                textColor: textColor,
                textSecondaryColor: textSecondaryColor,
                accentColor: accentColor,
                backgroundColor: backgroundColor,
                validator: (value) {
                  if (value == null) {
                    return 'Lütfen bölümünüzü seçin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildDropdown<Grade>(
                value: _selectedGrade,
                labelText: 'Sınıf',
                items: Grade.values.map((grade) {
                  return DropdownMenuItem<Grade>(
                    value: grade,
                    child: Text(grade.displayName),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedGrade = value;
                  });
                },
                textColor: textColor,
                textSecondaryColor: textSecondaryColor,
                accentColor: accentColor,
                backgroundColor: backgroundColor,
                validator: (value) {
                  if (value == null) {
                    return 'Lütfen sınıfınızı seçin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              _buildTextField(
                controller: _birthDateController,
                labelText: 'Doğum Tarihi',
                prefixIcon: CupertinoIcons.calendar,
                readOnly: true,
                textColor: textColor,
                textSecondaryColor: textSecondaryColor,
                accentColor: accentColor,
                focusNode: _birthDateFocus,
                textInputAction: TextInputAction.done,
                onTap: () => _selectBirthDate(context),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen doğum tarihinizi girin';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildGenderSelector(textColor, textSecondaryColor, accentColor),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector(
      Color textColor, Color textSecondaryColor, Color accentColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Cinsiyet',
          style: TextStyle(
            color: textSecondaryColor,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _gender = true;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: _gender ? accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _gender
                          ? accentColor
                          : textSecondaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.male,
                        color: _gender ? Colors.white : textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Erkek',
                        style: TextStyle(
                          color: _gender ? Colors.white : textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: InkWell(
                onTap: () {
                  setState(() {
                    _gender = false;
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: !_gender ? accentColor : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: !_gender
                          ? accentColor
                          : textSecondaryColor.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.female,
                        color: !_gender ? Colors.white : textSecondaryColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kadın',
                        style: TextStyle(
                          color: !_gender ? Colors.white : textSecondaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildNavigationButtons(
      Color textColor, Color accentColor, Color textSecondaryColor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Geri butonu veya Giriş Yap butonu (ilk adımdaysa)
        _currentStep > 0
            ? _buildButton(
                label: 'GERİ',
                onPressed: _previousStep,
                isPrimary: false,
                textColor: textColor,
                accentColor: accentColor,
                textSecondaryColor: textSecondaryColor,
              )
            : _buildButton(
                label: 'GİRİŞ YAP',
                onPressed: () =>
                    Navigator.pushReplacementNamed(context, '/login'),
                isPrimary: false,
                textColor: textColor,
                accentColor: accentColor,
                textSecondaryColor: textSecondaryColor,
              ),

        // İleri butonu veya Kayıt Ol butonu (son adımdaysa)
        _buildButton(
          label: _currentStep < 2 ? 'İLERİ' : 'KAYIT OL',
          onPressed: _currentStep < 2 ? _nextStep : _register,
          isPrimary: true,
          isLoading: _isLoading,
          textColor: textColor,
          accentColor: accentColor,
          textSecondaryColor: textSecondaryColor,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    required Color textColor,
    required Color textSecondaryColor,
    required Color accentColor,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePasswordVisibility,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    int? maxLength,
    void Function(String)? onChanged,
    required String? Function(String?) validator,
    TextInputAction textInputAction = TextInputAction.next,
    VoidCallback? onEditingComplete,
    FocusNode? focusNode,
  }) {
    final screenSize = MediaQuery.of(context).size;

    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
      textInputAction: textInputAction,
      onEditingComplete:
          onEditingComplete ?? () => FocusScope.of(context).nextFocus(),
      focusNode: focusNode,
      style: TextStyle(
          color: textColor, fontSize: math.min(16, screenSize.width * 0.04)),
      cursorColor: accentColor,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(
            color: textSecondaryColor,
            fontSize: math.min(14, screenSize.width * 0.035)),
        prefixIcon: Icon(prefixIcon,
            color: accentColor, size: math.min(20, screenSize.width * 0.05)),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  isPasswordVisible
                      ? CupertinoIcons.eye
                      : CupertinoIcons.eye_slash,
                  color: accentColor,
                  size: math.min(20, screenSize.width * 0.05),
                ),
                onPressed: onTogglePasswordVisibility,
              )
            : null,
        filled: true,
        fillColor: textColor.withOpacity(0.05),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: textSecondaryColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: textSecondaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide:
              BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: TextStyle(
            color: Colors.redAccent,
            fontSize: math.min(12, screenSize.width * 0.03)),
        contentPadding: EdgeInsets.symmetric(
            vertical: math.min(16, screenSize.height * 0.02),
            horizontal: math.min(20, screenSize.width * 0.05)),
        counterStyle: TextStyle(
            color: textSecondaryColor.withOpacity(0.5),
            fontSize: math.min(12, screenSize.width * 0.03)),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String labelText,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required Color textColor,
    required Color textSecondaryColor,
    required Color accentColor,
    required Color backgroundColor,
    required String? Function(T?) validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: textSecondaryColor),
        filled: true,
        fillColor: backgroundColor.withOpacity(0.5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: textSecondaryColor.withOpacity(0.3)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: textSecondaryColor.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: accentColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide:
              BorderSide(color: Colors.redAccent.withOpacity(0.5), width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.redAccent, width: 1.5),
        ),
        errorStyle: TextStyle(color: Colors.redAccent),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      ),
      dropdownColor: backgroundColor,
      style: TextStyle(color: textColor),
      isExpanded: true,
      icon: Icon(Icons.arrow_drop_down, color: accentColor),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    required Color textColor,
    required Color accentColor,
    required Color textSecondaryColor,
    bool isLoading = false,
  }) {
    final screenSize = MediaQuery.of(context).size;
    final buttonWidth = math.min(140.0, screenSize.width * 0.33);
    final buttonHeight = math.min(50.0, screenSize.height * 0.065);

    return Container(
      width: buttonWidth,
      height: buttonHeight,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        color: isPrimary ? accentColor : Colors.transparent,
        border: isPrimary
            ? null
            : Border.all(
                color: textSecondaryColor.withOpacity(0.3), width: 1.5),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: accentColor.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 0,
                  offset: const Offset(0, 4),
                ),
              ]
            : null,
      ),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          padding: EdgeInsets.symmetric(
              vertical: math.min(15, screenSize.height * 0.02)),
        ),
        child: isLoading
            ? SizedBox(
                width: math.min(20, screenSize.width * 0.05),
                height: math.min(20, screenSize.width * 0.05),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isPrimary ? Colors.white : textColor),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.white : textColor,
                  fontSize: math.min(15, screenSize.width * 0.038),
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
      ),
    );
  }

  void _formatPhoneNumber(String value) {
    // Telefon numarasını formatla
    String formatted = value.replaceAll(' ', '');
    if (formatted.length > 3) {
      formatted = formatted.replaceRange(3, 3, ' ');
    }
    if (formatted.length > 7) {
      formatted = formatted.replaceRange(7, 7, ' ');
    }
    _phoneController.value = TextEditingValue(
      text: formatted,
      selection:
          TextSelection.fromPosition(TextPosition(offset: formatted.length)),
    );
  }
}
