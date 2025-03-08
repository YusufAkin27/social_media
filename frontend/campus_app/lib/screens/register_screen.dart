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
import 'package:social_media/widgets/message_display.dart';
import 'dart:ui';
import 'package:flutter/cupertino.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({Key? key}) : super(key: key);

  @override
  _RegisterScreenState createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _surnameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _birthDateController = TextEditingController();
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

    _slideAnimation = Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(
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
        birthDate: DateTime.tryParse(_birthDateController.text) ?? DateTime.now(),
        gender: _gender,
      );

      try {
        // API'den yanıt al
        final response = await _studentService.signUp(createStudentRequest);
        
        setState(() {
          _isLoading = false;
          _isSuccess = response.isSuccess ?? false;
          _message = response.message;
        });

        if (_isSuccess) {
          Future.delayed(const Duration(milliseconds: 1500), () {
          Navigator.pushReplacementNamed(context, '/login');
          });
        }
      } catch (e) {
        // Beklenmeyen bir hata durumunda
        print('Beklenmeyen kayıt hatası: $e');
        setState(() {
          _isLoading = false;
          _isSuccess = false;
          _message = 'Beklenmeyen bir hata oluştu. Lütfen daha sonra tekrar deneyin.';
        });
      }
    }
  }

  Future<void> _selectBirthDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)), // 18 yaş varsayılan
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Colors.white,
              onPrimary: Colors.black,
              surface: Colors.black,
              onSurface: Colors.white,
            ),
            dialogBackgroundColor: Colors.black,
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _birthDateController.text = "${picked.toLocal()}".split(' ')[0]; // YYYY-MM-DD formatında
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Arka plan efekti
          _buildBackgroundEffect(),
          
          // Ana içerik
          SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
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
                  child: _buildRegisterForm(screenSize),
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

  Widget _buildRegisterForm(Size screenSize) {
    return Container(
      width: screenSize.width > 600 ? 550 : double.infinity,
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                // Logo veya İkon
                Container(
                  width: 90,
                  height: 90,
                  padding: const EdgeInsets.all(10),
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
                  child: SvgPicture.asset(
                        'assets/icons/register.svg',
                        colorFilter: const ColorFilter.mode(Colors.white, BlendMode.srcIn),
                      ),
                ),
                
                const SizedBox(height: 25),
                
                // Başlık
                ShaderMask(
                  shaderCallback: (Rect bounds) {
                    return LinearGradient(
                      colors: [Colors.white, Colors.white.withOpacity(0.8)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ).createShader(bounds);
                  },
                  child: const Text(
                    'ÜYE OL',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.5,
                      color: Colors.white,
                    ),
                  ),
                ),
                
                const SizedBox(height: 10),
                
                // Adım göstergesi
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(3, (index) => _buildStepIndicator(index)),
                ),
                
                const SizedBox(height: 5),
                
                // Adım başlığı
                      Text(
                  _getStepTitle(),
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
                
                      const SizedBox(height: 20),

                // Mesaj gösterimi
                      if (_message.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 20),
                    child: MessageDisplay(
                          isSuccess: _isSuccess,
                          message: _message,
                      maxCharacters: 100,
                    ),
                  ),
                
                // Form içeriği - Adıma göre farklı içerik gösterimi
                _currentStep == 0
                    ? _buildPersonalInfoStep()
                    : _currentStep == 1
                        ? _buildAccountInfoStep()
                        : _buildEducationInfoStep(),
                
                const SizedBox(height: 30),
                
                // Navigasyon butonları
                _buildNavigationButtons(),
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

  Widget _buildStepIndicator(int step) {
    bool isActive = _currentStep >= step;
    bool isCurrent = _currentStep == step;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: isCurrent ? 35 : 30,
            height: isCurrent ? 35 : 30,
            decoration: BoxDecoration(
              color: isActive ? Colors.white : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: isActive ? Colors.white : Colors.white.withOpacity(0.3),
                width: 2,
              ),
              boxShadow: isCurrent
                  ? [
                      BoxShadow(
                        color: Colors.white.withOpacity(0.2),
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
                  color: isActive ? Colors.black : Colors.white.withOpacity(0.7),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          if (step < 2)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 8),
              width: 20,
              height: 2,
              color: isActive ? Colors.white.withOpacity(0.7) : Colors.white.withOpacity(0.2),
            ),
        ],
      ),
    );
  }

  Widget _buildPersonalInfoStep() {
    return Column(
      children: [
        _buildTextField(
          controller: _nameController,
          labelText: 'Ad',
          prefixIcon: CupertinoIcons.person,
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
                          validator: (value) {
                            if (value == null || value.isEmpty || value.length < 5 || !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
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

  Widget _buildAccountInfoStep() {
    return Column(
      children: [
        _buildTextField(
                          controller: _usernameController,
                            labelText: 'Kullanıcı Adı',
          prefixIcon: CupertinoIcons.at,
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
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
              Text(
                'Güçlü bir şifre için:',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              _buildPasswordTip('En az 8 karakter kullanın'),
              _buildPasswordTip('Büyük ve küçük harfler kullanın'),
              _buildPasswordTip('Rakam ve özel karakterler ekleyin'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordTip(String tip) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Row(
        children: [
          Icon(
            Icons.check_circle_outline,
            color: Colors.white.withOpacity(0.7),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            tip,
            style: TextStyle(
              color: Colors.white.withOpacity(0.7),
              fontSize: 13,
            ),
                            ),
                          ],
                        ),
    );
  }

  Widget _buildEducationInfoStep() {
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
                                onTap: () => _selectBirthDate(context),
                                validator: (value) {
                                  if (value == null || value.isEmpty) {
                                    return 'Lütfen doğum tarihinizi girin';
                                  }
                                  return null;
                                },
                              ),
              const SizedBox(height: 20),
              _buildGenderSelector(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildGenderSelector() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
        Text(
          'Cinsiyet',
          style: TextStyle(
            color: Colors.white.withOpacity(0.8),
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
                    color: _gender ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _gender ? Colors.white : Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.male,
                        color: _gender ? Colors.black : Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Erkek',
                        style: TextStyle(
                          color: _gender ? Colors.black : Colors.white.withOpacity(0.7),
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
                    color: !_gender ? Colors.white : Colors.transparent,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: !_gender ? Colors.white : Colors.white.withOpacity(0.3),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.female,
                        color: !_gender ? Colors.black : Colors.white.withOpacity(0.7),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Kadın',
                        style: TextStyle(
                          color: !_gender ? Colors.black : Colors.white.withOpacity(0.7),
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

  Widget _buildNavigationButtons() {
    return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
        // Geri butonu veya Giriş Yap butonu (ilk adımdaysa)
        _currentStep > 0
            ? _buildButton(
                label: 'GERİ',
                              onPressed: _previousStep,
                isPrimary: false,
              )
            : _buildButton(
                label: 'GİRİŞ YAP',
                onPressed: () => Navigator.pushReplacementNamed(context, '/login'),
                isPrimary: false,
              ),
        
        // İleri butonu veya Kayıt Ol butonu (son adımdaysa)
        _buildButton(
          label: _currentStep < 2 ? 'İLERİ' : 'KAYIT OL',
          onPressed: _currentStep < 2 ? _nextStep : _register,
          isPrimary: true,
          isLoading: _isLoading,
        ),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String labelText,
    required IconData prefixIcon,
    bool isPassword = false,
    bool isPasswordVisible = false,
    VoidCallback? onTogglePasswordVisibility,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    int? maxLength,
    void Function(String)? onChanged,
    required String? Function(String?) validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword && !isPasswordVisible,
      readOnly: readOnly,
      onTap: onTap,
      keyboardType: keyboardType,
      maxLength: maxLength,
      onChanged: onChanged,
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
        counterStyle: TextStyle(color: Colors.white.withOpacity(0.5)),
      ),
      validator: validator,
    );
  }

  Widget _buildDropdown<T>({
    required T? value,
    required String labelText,
    required List<DropdownMenuItem<T>> items,
    required void Function(T?) onChanged,
    required String? Function(T?) validator,
  }) {
    return DropdownButtonFormField<T>(
      value: value,
      decoration: InputDecoration(
        labelText: labelText,
        labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
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
      dropdownColor: Colors.black,
      style: const TextStyle(color: Colors.white),
      isExpanded: true,
      icon: Icon(Icons.arrow_drop_down, color: Colors.white.withOpacity(0.7)),
      items: items,
      onChanged: onChanged,
      validator: validator,
    );
  }

  Widget _buildButton({
    required String label,
    required VoidCallback onPressed,
    required bool isPrimary,
    bool isLoading = false,
  }) {
    return Container(
      width: 140,
      height: 50,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(15),
        gradient: isPrimary
            ? LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.9),
                  Colors.white,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: isPrimary
            ? null
            : Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
        boxShadow: isPrimary
            ? [
                BoxShadow(
                  color: Colors.white.withOpacity(0.1),
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
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                      isPrimary ? Colors.black : Colors.white),
                ),
              )
            : Text(
                label,
                style: TextStyle(
                  color: isPrimary ? Colors.black : Colors.white,
                  fontSize: 15,
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
      selection: TextSelection.fromPosition(TextPosition(offset: formatted.length)),
    );
  }
} 