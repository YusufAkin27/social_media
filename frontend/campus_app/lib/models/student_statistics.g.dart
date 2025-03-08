// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'student_statistics.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StudentStatistics _$StudentStatisticsFromJson(Map<String, dynamic> json) =>
    StudentStatistics(
      totalStudents: (json['totalStudents'] as num).toInt(),
      activeStudents: (json['activeStudents'] as num).toInt(),
      inactiveStudents: (json['inactiveStudents'] as num).toInt(),
      deletedStudents: (json['deletedStudents'] as num).toInt(),
      departmentDistribution:
          Map<String, int>.from(json['departmentDistribution'] as Map),
      facultyDistribution:
          Map<String, int>.from(json['facultyDistribution'] as Map),
      genderDistribution:
          Map<String, int>.from(json['genderDistribution'] as Map),
      gradeDistribution:
          Map<String, int>.from(json['gradeDistribution'] as Map),
    );

Map<String, dynamic> _$StudentStatisticsToJson(StudentStatistics instance) =>
    <String, dynamic>{
      'totalStudents': instance.totalStudents,
      'activeStudents': instance.activeStudents,
      'inactiveStudents': instance.inactiveStudents,
      'deletedStudents': instance.deletedStudents,
      'departmentDistribution': instance.departmentDistribution,
      'facultyDistribution': instance.facultyDistribution,
      'genderDistribution': instance.genderDistribution,
      'gradeDistribution': instance.gradeDistribution,
    };
