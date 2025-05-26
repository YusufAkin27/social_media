import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:social_media/enums/faculty.dart';
import 'package:social_media/enums/department.dart';
import 'package:social_media/enums/grade.dart';
import 'package:social_media/services/studentService.dart';
import 'package:dio/dio.dart';
import 'dart:ui' as ui;
import 'package:social_media/models/update_student_profile_request.dart';
import 'package:provider/provider.dart';
import 'package:social_media/theme/theme_provider.dart';
import 'package:social_media/theme/app_theme.dart';

class ProfileEditScreen extends StatefulWidget {
  const ProfileEditScreen({Key? key}) : super(key: key);

  @override
  _ProfileEditScreenState createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();

  // StudentService için instance
  final StudentService _studentService = StudentService();

  // Kullanıcı bilgileri
  int? _userId;
  String? _profilePhotoUrl;
  TextEditingController _firstNameController = TextEditingController();
  TextEditingController _lastNameController = TextEditingController();
  TextEditingController _usernameController = TextEditingController();
  TextEditingController _emailController = TextEditingController();
  TextEditingController _mobilePhoneController = TextEditingController();
  DateTime? _birthDate;
  bool? _gender;
  Faculty? _selectedFaculty;
  Department? _selectedDepartment;
  Grade? _selectedGrade;
  TextEditingController _bioController = TextEditingController();
  int _followersCount = 0;
  int _followingCount = 0;
  bool _profilePhotoDeleted = false;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _mobilePhoneController.dispose();
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _loadUserProfile() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      // Dio ile profil bilgilerini getir
      final dio = Dio();
      final response = await dio.get(
        'http://192.168.89.61:8080/v1/api/student/profile',
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Profile load response: ${response.statusCode}');
      print('Profile load data: ${response.data}');

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = response.data;

        if (responseData['success'] == true && responseData['data'] != null) {
          final userData = responseData['data'];

          setState(() {
            _userId = userData['userId'];
            _profilePhotoUrl = userData['profilePhoto'];
            _firstNameController.text = userData['firstName'] ?? '';
            _lastNameController.text = userData['lastName'] ?? '';
            _usernameController.text = userData['username'] ?? '';
            _emailController.text = userData['email'] ?? '';
            _mobilePhoneController.text = userData['mobilePhone'] ?? '';

            // Doğum tarihini parse et
            if (userData['birthDate'] != null) {
              try {
                _birthDate = DateTime.parse(userData['birthDate']);
              } catch (e) {
                print('Tarih dönüştürme hatası: $e');
              }
            }

            _gender = userData['gender'];
            // 'biography' veya 'biograpy' alanını kontrol et (API'ye göre adı değişebilir)
            if (userData['biography'] != null) {
              _bioController.text = userData['biography'] ?? '';
            } else if (userData['biograpy'] != null) {
              _bioController.text = userData['biograpy'] ?? '';
            } else {
              _bioController.text = '';
            }

            _followersCount = userData['follower']?.toInt() ?? 0;
            _followingCount = userData['following']?.toInt() ?? 0;

            // Enum değerlerini seç
            try {
              if (userData['faculty'] != null && userData['faculty'] is int) {
                int facultyIndex = userData['faculty'];
                if (facultyIndex >= 0 && facultyIndex < Faculty.values.length) {
                  _selectedFaculty = Faculty.values[facultyIndex];
                }
              }

              if (userData['department'] != null &&
                  userData['department'] is int) {
                int departmentIndex = userData['department'];
                if (departmentIndex >= 0 &&
                    departmentIndex < Department.values.length) {
                  _selectedDepartment = Department.values[departmentIndex];
                }
              }

              if (userData['grade'] != null && userData['grade'] is int) {
                int gradeIndex = userData['grade'];
                if (gradeIndex >= 0 && gradeIndex < Grade.values.length) {
                  _selectedGrade = Grade.values[gradeIndex];
                }
              }
            } catch (e) {
              print('Enum dönüşüm hatası: $e');
            }

            _isLoading = false;
          });
        } else {
          setState(() {
            _errorMessage =
                responseData['message'] ?? 'Profil bilgileri alınamadı';
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'HTTP Hatası: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Profil bilgileri yükleme hatası: $e');
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source);
      if (pickedFile != null) {
        setState(() {
          _imageFile = File(pickedFile.path);
        });

        // Yeni seçilen fotoğrafı kullanıcıya göster ve güncelleme seçeneği sun
        _showPhotoUpdateDialog();
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Resim seçilirken hata oluştu: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  // Yeni metot - Fotoğraf güncelleme onay dialogu
  void _showPhotoUpdateDialog() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;
    final secondaryTextColor =
        isDarkMode ? AppColors.secondaryText : AppColors.lightSecondaryText;
    final accentColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: backgroundColor,
          contentPadding: const EdgeInsets.all(16),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(
            'Profil Fotoğrafını Güncelle',
            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Seçtiğiniz fotoğrafı profil fotoğrafınız olarak ayarlamak istiyor musunuz?',
                style: TextStyle(color: secondaryTextColor),
              ),
              const SizedBox(height: 16),
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: accentColor, width: 2),
                ),
                child: ClipOval(
                  child: Image.file(
                    _imageFile!,
                    width: 120,
                    height: 120,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: Text(
                'İptal',
                style: TextStyle(color: secondaryTextColor),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _updateProfilePhoto();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: const Text('Güncelle'),
            ),
          ],
        );
      },
    );
  }

  // Yeni metot - Profil fotoğrafını güncelle
  Future<void> _updateProfilePhoto() async {
    if (_imageFile == null) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      // Profil fotoğrafı için form-data oluştur
      final formData = FormData();

      // Dosyayı ekle
      final fileName = _imageFile!.path.split('/').last;
      final multipartFile = await MultipartFile.fromFile(
        _imageFile!.path,
        filename: fileName,
      );

      // 'file' parametresi ile ekle
      formData.files.add(MapEntry('file', multipartFile));

      // API endpointine istek at
      final dio = Dio();
      final uploadResponse = await dio.post(
        'http://192.168.89.61:8080/v1/api/student/profile-photo',
        data: formData,
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
          },
        ),
      );

      print('Photo upload response: ${uploadResponse.statusCode}');
      print('Photo upload data: ${uploadResponse.data}');

      if (uploadResponse.statusCode == 200 ||
          uploadResponse.statusCode == 201) {
        // Başarılı yükleme sonrası profil bilgilerini yenile
        await _loadUserProfile();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil fotoğrafı başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                'Fotoğraf yüklenemedi: ${uploadResponse.data['message'] ?? 'Bilinmeyen hata'}'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Fotoğraf yükleme hatası: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _showImagePicker() {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final backgroundColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;
    final secondaryTextColor =
        isDarkMode ? AppColors.secondaryText : AppColors.lightSecondaryText;
    final errorColor = isDarkMode ? AppColors.error : AppColors.lightError;

    showModalBottomSheet(
      context: context,
      backgroundColor: backgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 5,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: secondaryTextColor.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            ListTile(
              leading: Icon(Icons.photo_camera, color: textColor),
              title: Text('Kamera', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: Icon(Icons.photo_library, color: textColor),
              title: Text('Galeri', style: TextStyle(color: textColor)),
              onTap: () {
                Navigator.pop(context);
                _pickImage(ImageSource.gallery);
              },
            ),
            if (_profilePhotoUrl != null || _imageFile != null)
              ListTile(
                leading: Icon(Icons.delete, color: errorColor),
                title: Text('Profil Fotoğrafını Kaldır',
                    style: TextStyle(color: errorColor)),
                onTap: () async {
                  Navigator.pop(context);

                  // Profil fotoğrafını sil
                  if (_profilePhotoUrl != null) {
                    setState(() {
                      _isLoading = true;
                    });

                    try {
                      final prefs = await SharedPreferences.getInstance();
                      final accessToken = prefs.getString('accessToken');

                      // Direkt API'ye istek at
                      final dio = Dio();
                      final response = await dio.delete(
                        'http://192.168.89.61:8080/v1/api/student/profile-photo',
                        options: Options(
                          headers: {
                            'Authorization': 'Bearer $accessToken',
                          },
                        ),
                      );

                      print('Photo delete response: ${response.statusCode}');
                      print('Photo delete data: ${response.data}');

                      final responseBody =
                          response.data as Map<String, dynamic>;
                      final isSuccess = responseBody['success'] ?? false;

                      if (isSuccess) {
                        setState(() {
                          _profilePhotoUrl = null;
                          _profilePhotoDeleted = true;
                          _imageFile = null;
                        });

                        // Profil bilgilerini yenile
                        await _loadUserProfile();

                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Profil fotoğrafı başarıyla silindi'),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } else {
                        setState(() {
                          _isLoading = false;
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Hata: ${responseBody['message'] ?? "Bilinmeyen bir hata oluştu"}'),
                            backgroundColor: Colors.redAccent,
                          ),
                        );
                      }
                    } catch (e) {
                      setState(() {
                        _isLoading = false;
                      });
                      print('Profil fotoğrafı silme hatası: $e');
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('İşlem sırasında bir hata oluştu: $e'),
                          backgroundColor: Colors.redAccent,
                        ),
                      );
                    }
                  } else if (_imageFile != null) {
                    setState(() {
                      _imageFile = null;
                    });
                  }
                },
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectDate(BuildContext context) async {
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final isDarkMode = themeProvider.isDarkMode;
    final primaryColor = isDarkMode ? AppColors.accent : AppColors.lightAccent;
    final backgroundColor =
        isDarkMode ? AppColors.cardBackground : AppColors.lightCardBackground;
    final textColor =
        isDarkMode ? AppColors.primaryText : AppColors.lightPrimaryText;

    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate:
          _birthDate ?? DateTime.now().subtract(const Duration(days: 365 * 20)),
      firstDate: DateTime(1950),
      lastDate: DateTime.now(),
      builder: (BuildContext context, Widget? child) {
        return Theme(
          data: isDarkMode
              ? ThemeData.dark().copyWith(
                  primaryColor: primaryColor,
                  colorScheme: ColorScheme.dark(
                    primary: primaryColor,
                    onPrimary: Colors.white,
                    surface: backgroundColor,
                    onSurface: textColor,
                  ),
                  dialogBackgroundColor: backgroundColor,
                )
              : ThemeData.light().copyWith(
                  primaryColor: primaryColor,
                  colorScheme: ColorScheme.light(
                    primary: primaryColor,
                    onPrimary: Colors.white,
                    surface: backgroundColor,
                    onSurface: textColor,
                  ),
                  dialogBackgroundColor: backgroundColor,
                ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _birthDate) {
      setState(() {
        _birthDate = picked;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isSaving = true;
      _errorMessage = null;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString('accessToken') ?? '';

      // Profil güncelleme verilerini oluştur
      Map<String, dynamic> updateData = {
        'firstName': _firstNameController.text,
        'lastName': _lastNameController.text,
        'username': _usernameController.text,
        'mobilePhone': _mobilePhoneController.text,
        'biograpy': _bioController.text, // API'ye uygun alan adı
      };

      // Opsiyonel alanları ekle (sadece null değilse)
      if (_birthDate != null) {
        // DateTime'ı ISO formatında string'e dönüştür
        updateData['birthDate'] = _birthDate!.toIso8601String().split('T')[0];
      }

      if (_gender != null) {
        updateData['gender'] = _gender;
      }

      if (_selectedFaculty != null) {
        updateData['faculty'] = _selectedFaculty!.index;
      }

      if (_selectedDepartment != null) {
        updateData['department'] = _selectedDepartment!.index;
      }

      if (_selectedGrade != null) {
        updateData['grade'] = _selectedGrade!.index;
      }

      print('Sending profile update with data: $updateData');

      // Direkt API endpointine PUT isteği at
      final dio = Dio();
      final updateResponse = await dio.put(
        'http://192.168.89.61:8080/v1/api/student/profile',
        data: jsonEncode(updateData),
        options: Options(
          headers: {
            'Authorization': 'Bearer $accessToken',
            'Content-Type': 'application/json',
          },
        ),
      );

      print('Profile update response: ${updateResponse.statusCode}');
      print('Profile update data: ${updateResponse.data}');

      final responseBody = updateResponse.data as Map<String, dynamic>;
      final isSuccess = responseBody['success'] ?? false;

      if (isSuccess) {
        setState(() {
          _isSaving = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profil başarıyla güncellendi'),
            backgroundColor: Colors.green,
          ),
        );

        // Kullanıcı profiline geri dön
        Navigator.pop(context, true); // true: profil güncellendi
      } else {
        setState(() {
          _errorMessage = responseBody['message'] ??
              'Profil güncellenirken bir hata oluştu';
          _isSaving = false;
        });
      }
    } catch (e) {
      print('Profil güncelleme hatası: $e');
      setState(() {
        _errorMessage = 'Bağlantı hatası: $e';
        _isSaving = false;
      });
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
    final surfaceColor =
        isDarkMode ? AppColors.surfaceColor : AppColors.lightSurfaceColor;
    final errorColor = isDarkMode ? AppColors.error : AppColors.lightError;
    final successColor =
        isDarkMode ? AppColors.success : AppColors.lightSuccess;

    return Scaffold(
      backgroundColor: backgroundColor,
      appBar: AppBar(
        backgroundColor: backgroundColor,
        title: Text('Profili Düzenle', style: TextStyle(color: textColor)),
        iconTheme: IconThemeData(color: textColor),
        actions: [
          TextButton(
            onPressed: _isSaving ? null : _saveProfile,
            child: _isSaving
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      color: textColor,
                      strokeWidth: 2,
                    ),
                  )
                : Text(
                    'Kaydet',
                    style: TextStyle(
                      color: accentColor,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
          ),
        ],
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator(color: accentColor))
          : _errorMessage != null
              ? _buildErrorWidget(
                  backgroundColor, errorColor, accentColor, textColor)
              : _buildForm(backgroundColor, cardColor, textColor,
                  secondaryTextColor, accentColor, surfaceColor),
    );
  }

  Widget _buildErrorWidget(Color backgroundColor, Color errorColor,
      Color accentColor, Color textColor) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: errorColor,
              size: 60,
            ),
            const SizedBox(height: 16),
            Text(
              'Bir hata oluştu',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: textColor,
                  ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Bilinmeyen bir hata oluştu',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: textColor.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadUserProfile,
              icon: const Icon(Icons.refresh),
              label: const Text('Tekrar Dene'),
              style: ElevatedButton.styleFrom(
                backgroundColor: accentColor,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(Color backgroundColor, Color cardColor, Color textColor,
      Color secondaryTextColor, Color accentColor, Color surfaceColor) {
    return Form(
      key: _formKey,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Profil fotoğrafı
          Center(
            child: Stack(
              children: [
                CircleAvatar(
                  radius: 60,
                  backgroundColor: surfaceColor,
                  backgroundImage: _imageFile != null
                      ? FileImage(_imageFile!) as ImageProvider
                      : _profilePhotoUrl != null
                          ? CachedNetworkImageProvider(_profilePhotoUrl!)
                          : null,
                  child: (_imageFile == null && _profilePhotoUrl == null)
                      ? Icon(Icons.person, size: 60, color: secondaryTextColor)
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.camera_alt,
                          color: Colors.white, size: 20),
                      onPressed: _showImagePicker,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Takipçi ve Takip Edilen Sayıları
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildStatItem('Takipçiler', _followersCount, () {
                Navigator.pushNamed(context, '/followers',
                    arguments: {'username': _usernameController.text});
              }),
              Container(
                height: 30,
                width: 1,
                color: Colors.grey[700],
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _buildStatItem('Takip Edilen', _followingCount, () {
                Navigator.pushNamed(context, '/following',
                    arguments: {'username': _usernameController.text});
              }),
            ],
          ),

          const SizedBox(height: 24),

          // Ad ve Soyad
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _firstNameController,
                  decoration: InputDecoration(
                    labelText: 'Ad',
                    labelStyle: const TextStyle(color: Colors.white70),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Ad gerekli';
                    }
                    return null;
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextFormField(
                  controller: _lastNameController,
                  decoration: InputDecoration(
                    labelText: 'Soyad',
                    labelStyle: const TextStyle(color: Colors.white70),
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
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Soyad gerekli';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Kullanıcı adı
          TextFormField(
            controller: _usernameController,
            decoration: InputDecoration(
              labelText: 'Kullanıcı Adı',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon:
                  const Icon(Icons.alternate_email, color: Colors.white60),
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
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Kullanıcı adı gerekli';
              }
              if (value.length < 3) {
                return 'Kullanıcı adı en az 3 karakter olmalı';
              }
              if (!RegExp(r'^[a-zA-Z0-9_.]+$').hasMatch(value)) {
                return 'Geçersiz karakterler içeriyor';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // E-posta (salt okunur)
          TextFormField(
            controller: _emailController,
            decoration: InputDecoration(
              labelText: 'E-posta',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.email, color: Colors.white60),
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
            readOnly: true, // E-posta değiştirilemez
            enabled: false,
          ),
          const SizedBox(height: 16),

          // Telefon numarası
          TextFormField(
            controller: _mobilePhoneController,
            decoration: InputDecoration(
              labelText: 'Telefon Numarası',
              labelStyle: const TextStyle(color: Colors.white70),
              prefixIcon: const Icon(Icons.phone, color: Colors.white60),
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
            keyboardType: TextInputType.phone,
            validator: (value) {
              if (value == null || value.isEmpty) {
                return null; // Telefon numarası zorunlu değil
              }
              if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(value)) {
                return 'Geçerli bir telefon numarası girin';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),

          // Doğum tarihi
          InkWell(
            onTap: () => _selectDate(context),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.calendar_today, color: Colors.white60),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _birthDate == null
                          ? 'Doğum Tarihi (İsteğe bağlı)'
                          : DateFormat('dd.MM.yyyy').format(_birthDate!),
                      style: TextStyle(
                        color:
                            _birthDate == null ? Colors.white70 : Colors.white,
                      ),
                    ),
                  ),
                  const Icon(Icons.arrow_drop_down, color: Colors.white60),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Cinsiyet
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Cinsiyet (İsteğe bağlı)',
                  style: TextStyle(color: Colors.white70),
                ),
                Row(
                  children: [
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text(
                          'Erkek',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: true,
                        groupValue: _gender,
                        onChanged: (bool? value) {
                          setState(() {
                            _gender = value;
                          });
                        },
                        activeColor: Colors.indigoAccent,
                      ),
                    ),
                    Expanded(
                      child: RadioListTile<bool>(
                        title: const Text(
                          'Kadın',
                          style: TextStyle(color: Colors.white),
                        ),
                        value: false,
                        groupValue: _gender,
                        onChanged: (bool? value) {
                          setState(() {
                            _gender = value;
                          });
                        },
                        activeColor: Colors.indigoAccent,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Fakülte Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Fakülte',
                  style: TextStyle(color: Colors.white70),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<Faculty>(
                    value: _selectedFaculty,
                    hint: const Text(
                      'Fakülte seçin',
                      style: TextStyle(color: Colors.white60),
                    ),
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                    isExpanded: true,
                    dropdownColor: Colors.grey[800],
                    items: Faculty.values.map((Faculty faculty) {
                      return DropdownMenuItem<Faculty>(
                        value: faculty,
                        child: Text(
                          faculty.displayName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (Faculty? newValue) {
                      setState(() {
                        _selectedFaculty = newValue;
                        // Fakülte değişince bölüm sıfırlanır
                        _selectedDepartment = null;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Bölüm Dropdown (Fakülteye bağlı)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Bölüm',
                  style: TextStyle(color: Colors.white70),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<Department>(
                    value: _selectedDepartment,
                    hint: const Text(
                      'Bölüm seçin',
                      style: TextStyle(color: Colors.white60),
                    ),
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                    isExpanded: true,
                    dropdownColor: Colors.grey[800],
                    disabledHint: _selectedFaculty == null
                        ? const Text(
                            'Önce fakülte seçin',
                            style: TextStyle(color: Colors.white60),
                          )
                        : null,
                    items: _selectedFaculty != null
                        ? _selectedFaculty!.departments
                            .map((Department department) {
                            return DropdownMenuItem<Department>(
                              value: department,
                              child: Text(
                                department.displayName,
                                style: const TextStyle(color: Colors.white),
                              ),
                            );
                          }).toList()
                        : <DropdownMenuItem<Department>>[],
                    onChanged: _selectedFaculty != null
                        ? (Department? newValue) {
                            setState(() {
                              _selectedDepartment = newValue;
                            });
                          }
                        : null,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Sınıf Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.grey[900],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sınıf',
                  style: TextStyle(color: Colors.white70),
                ),
                DropdownButtonHideUnderline(
                  child: DropdownButton<Grade>(
                    value: _selectedGrade,
                    hint: const Text(
                      'Sınıf seçin',
                      style: TextStyle(color: Colors.white60),
                    ),
                    icon:
                        const Icon(Icons.arrow_drop_down, color: Colors.white),
                    isExpanded: true,
                    dropdownColor: Colors.grey[800],
                    items: Grade.values.map((Grade grade) {
                      return DropdownMenuItem<Grade>(
                        value: grade,
                        child: Text(
                          grade.displayName,
                          style: const TextStyle(color: Colors.white),
                        ),
                      );
                    }).toList(),
                    onChanged: (Grade? newValue) {
                      setState(() {
                        _selectedGrade = newValue;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Hakkımda / Bio
          TextFormField(
            controller: _bioController,
            decoration: InputDecoration(
              labelText: 'Hakkımda',
              labelStyle: const TextStyle(color: Colors.white70),
              alignLabelWithHint: true,
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
            maxLines: 5,
            maxLength: 200,
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, int count, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Column(
          children: [
            Text(
              count.toString(),
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
