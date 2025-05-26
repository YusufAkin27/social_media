import 'package:json_annotation/json_annotation.dart';
import 'package:social_media/enums/department.dart';
import 'package:social_media/enums/grade.dart';
import 'package:social_media/enums/faculty.dart';

part 'create_student_request.g.dart';

@JsonSerializable()
class CreateStudentRequest {
  final String firstName; // Öğrenci Adı
  final String lastName; // Öğrenci Soyadı
  final String username; // Kullanıcı adı
  final String password; // Şifre
  final String email; // E-posta Adresi
  final String mobilePhone; // Telefon Numarası

  @JsonKey(fromJson: _departmentFromJson, toJson: _departmentToJson)
  final Department department; // Bölüm

  @JsonKey(fromJson: _facultyFromJson, toJson: _facultyToJson)
  final Faculty faculty; // Fakülte

  @JsonKey(fromJson: _gradeFromJson, toJson: _gradeToJson)
  final Grade grade; // Sınıf

  @JsonKey(name: 'birthDate')
  final DateTime birthDate; // Doğum Tarihi
  final bool? gender; // Cinsiyet (true: Erkek, false: Kadın)

  CreateStudentRequest({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.email,
    required this.mobilePhone,
    required this.department,
    required this.faculty,
    required this.grade,
    required this.birthDate,
    required this.gender,
  });

  factory CreateStudentRequest.fromJson(Map<String, dynamic> json) => _$CreateStudentRequestFromJson(json);
  Map<String, dynamic> toJson() => _$CreateStudentRequestToJson(this);
}
// JSON Dönüşüm Fonksiyonları
Department _departmentFromJson(String department) => Department.values.firstWhere((e) => e.name == department);
String _departmentToJson(Department department) => department.name;

Faculty _facultyFromJson(String faculty) => Faculty.values.firstWhere((e) => e.name == faculty);
String _facultyToJson(Faculty faculty) => faculty.name;

Grade _gradeFromJson(String grade) => Grade.values.firstWhere((e) => e.name == grade);
String _gradeToJson(Grade grade) => grade.name;

