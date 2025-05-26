import 'package:json_annotation/json_annotation.dart';
import 'package:social_media/enums/department.dart';
import 'package:social_media/enums/grade.dart';
import 'package:social_media/enums/faculty.dart';
part 'update_student_profile_request.g.dart';

@JsonSerializable()
class UpdateStudentProfileRequest {
  final String firstName; // Öğrenci Adı
  final String lastName; // Öğrenci Soyadı
  final String mobilePhone; // Telefon Numarası
  final String username; // Kullanıcı adı
  final Department department; // Bölüm
  final String biography; // Biyografi
  @JsonKey(name: 'birthDate')
  final DateTime birthDate; // Doğum Tarihi
  final Faculty faculty; // Fakülte
  final Grade grade; // Sınıf
  final bool? gender; // Cinsiyet (true: Erkek, false: Kadın)

  UpdateStudentProfileRequest({
    required this.firstName,
    required this.lastName,
    required this.mobilePhone,
    required this.username,
    required this.department,
    required this.biography,
    required this.birthDate,
    required this.faculty,
    required this.grade,
    required this.gender,
  });

  factory UpdateStudentProfileRequest.fromJson(Map<String, dynamic> json) => _$UpdateStudentProfileRequestFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateStudentProfileRequestToJson(this);
} 