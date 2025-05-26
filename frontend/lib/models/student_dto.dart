import 'package:json_annotation/json_annotation.dart';
import 'package:social_media/enums/department.dart';
import 'package:social_media/enums/grade.dart';
import 'package:social_media/enums/faculty.dart';

part 'student_dto.g.dart';

@JsonSerializable()
class StudentDTO {
  final int userId; // long türü Dart'ta int olarak temsil edilir
  final String firstName; // Öğrencinin adı
  final String lastName; // Öğrencinin soyadı
  final String tcIdentityNumber; // TC Kimlik Numarası
  final String username; // Kullanıcı adı
  final String email; // E-posta adresi
  final String mobilePhone; // Telefon numarası
  @JsonKey(name: 'birthDate')
  final DateTime birthDate; // Doğum tarihi
  final bool? gender; // Cinsiyet (true: Erkek, false: Kadın)
  final Faculty faculty; // Fakülte
  final Department department; // Bölüm
  final Grade grade; // Sınıf
  final String profilePhoto; // Profil fotoğrafı URL veya dosya yolu
  final bool? isActive; // Hesap aktif mi?
  final bool? isDeleted; // Hesap silinmiş mi?
  final bool isPrivate; // Profil gizli mi?
  final String biography; // Biyografi
  final int popularityScore; // Popülerlik skoru

  // Takip ilişkileri
  final int follower; // Takipçi sayısı
  final int following; // Takip edilenler sayısı
  final int block; // Engellenen kullanıcı sayısı

  // Arkadaşlık istekleri
  final int friendRequestsReceived; // Gelen arkadaşlık istekleri
  final int friendRequestsSent; // Gönderilen arkadaşlık istekleri

  // İçerikler
  final int posts; // Gönderi sayısı
  final int stories; // Hikaye sayısı
  final int featuredStories; // Öne çıkan hikaye sayısı

  // Etkileşimler
  final int likedContents; // Beğendiği içeriklerin sayısı
  final int comments; // Yaptığı yorumların sayısı

  StudentDTO({
    required this.userId,
    required this.firstName,
    required this.lastName,
    required this.tcIdentityNumber,
    required this.username,
    required this.email,
    required this.mobilePhone,
    required this.birthDate,
    required this.gender,
    required this.faculty,
    required this.department,
    required this.grade,
    required this.profilePhoto,
    required this.isActive,
    required this.isDeleted,
    required this.isPrivate,
    required this.biography,
    required this.popularityScore,
    required this.follower,
    required this.following,
    required this.block,
    required this.friendRequestsReceived,
    required this.friendRequestsSent,
    required this.posts,
    required this.stories,
    required this.featuredStories,
    required this.likedContents,
    required this.comments,
  });

  // Create an empty StudentDTO with default values for use during errors
  factory StudentDTO.createEmpty() {
    return StudentDTO(
      userId: 0,
      firstName: 'Bilinmeyen',
      lastName: 'Kullanıcı',
      tcIdentityNumber: '',
      username: 'Kullanıcı',
      email: '',
      mobilePhone: '',
      birthDate: DateTime.now(),
      gender: null,
      faculty: Faculty.values[0],
      department: Department.values[0],
      grade: Grade.values[0],
      profilePhoto: '',
      isActive: true,
      isDeleted: false,
      isPrivate: false,
      biography: '',
      popularityScore: 0,
      follower: 0,
      following: 0,
      block: 0,
      friendRequestsReceived: 0,
      friendRequestsSent: 0,
      posts: 0,
      stories: 0,
      featuredStories: 0,
      likedContents: 0,
      comments: 0,
    );
  }

  // Custom fromJson method to handle null values
  factory StudentDTO.fromJson(Map<String, dynamic> json) {
    try {
      // String tarihi DateTime'a çevirme
      DateTime parsedBirthDate;
      try {
        if (json['birthDate'] is String) {
          parsedBirthDate = DateTime.parse(json['birthDate']);
        } else if (json['birthDate'] is DateTime) {
          parsedBirthDate = json['birthDate'];
        } else {
          parsedBirthDate = DateTime.now();
        }
      } catch (e) {
        print('Tarih çevirme hatası: $e');
        parsedBirthDate = DateTime.now();
      }

      return StudentDTO(
        userId: json['userId'] as int? ?? 0,
        firstName: json['firstName'] as String? ?? '',
        lastName: json['lastName'] as String? ?? '',
        tcIdentityNumber: json['tcIdentityNumber'] as String? ?? '',
        username: json['username'] as String? ?? '',
        email: json['email'] as String? ?? '',
        mobilePhone: json['mobilePhone'] as String? ?? '',
        birthDate: parsedBirthDate,
        gender: json['gender'] as bool?,
        faculty: Faculty.values[json['faculty'] as int? ?? 0],
        department: Department.values[json['department'] as int? ?? 0],
        grade: Grade.values[json['grade'] as int? ?? 0],
        profilePhoto: json['profilePhoto'] as String? ?? '',
        isActive: json['isActive'] as bool?,
        isDeleted: json['isDeleted'] as bool?,
        isPrivate: json['isPrivate'] as bool? ?? false,
        biography: json['biography'] as String? ?? '',
        popularityScore: json['popularityScore'] as int? ?? 0,
        follower: json['follower'] as int? ?? 0,
        following: json['following'] as int? ?? 0,
        block: json['block'] as int? ?? 0,
        friendRequestsReceived: json['friendRequestsReceived'] as int? ?? 0,
        friendRequestsSent: json['friendRequestsSent'] as int? ?? 0,
        posts: json['posts'] as int? ?? 0,
        stories: json['stories'] as int? ?? 0,
        featuredStories: json['featuredStories'] as int? ?? 0,
        likedContents: json['likedContents'] as int? ?? 0,
        comments: json['comments'] as int? ?? 0,
      );
    } catch (e) {
      print('StudentDTO parsing error: $e');
      return StudentDTO.createEmpty();
    }
  }

  Map<String, dynamic> toJson() => _$StudentDTOToJson(this);
} 