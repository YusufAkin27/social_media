import 'package:json_annotation/json_annotation.dart';

part 'student_statistics.g.dart';

@JsonSerializable()
class StudentStatistics {
  final int totalStudents; // Toplam öğrenci sayısı
  final int activeStudents; // Aktif öğrenci sayısı
  final int inactiveStudents; // Pasif öğrenci sayısı
  final int deletedStudents; // Silinmiş öğrenci sayısı
  final Map<String, int> departmentDistribution; // Departman dağılımı
  final Map<String, int> facultyDistribution; // Fakülte dağılımı
  final Map<String, int> genderDistribution; // Cinsiyet dağılımı
  final Map<String, int> gradeDistribution; // Sınıf durumu

  StudentStatistics({
    required this.totalStudents,
    required this.activeStudents,
    required this.inactiveStudents,
    required this.deletedStudents,
    required this.departmentDistribution,
    required this.facultyDistribution,
    required this.genderDistribution,
    required this.gradeDistribution,
  });

  factory StudentStatistics.fromJson(Map<String, dynamic> json) => _$StudentStatisticsFromJson(json);
  Map<String, dynamic> toJson() => _$StudentStatisticsToJson(this);
} 