// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_student_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CreateStudentRequest _$CreateStudentRequestFromJson(
        Map<String, dynamic> json) =>
    CreateStudentRequest(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      username: json['username'] as String,
      password: json['password'] as String,
      email: json['email'] as String,
      mobilePhone: json['mobilePhone'] as String,
      department: _departmentFromJson(json['department'] as String),
      faculty: _facultyFromJson(json['faculty'] as String),
      grade: _gradeFromJson(json['grade'] as String),
      birthDate: DateTime.parse(json['birthDate'] as String),
      gender: json['gender'] as bool?,
    );

Map<String, dynamic> _$CreateStudentRequestToJson(
        CreateStudentRequest instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'username': instance.username,
      'password': instance.password,
      'email': instance.email,
      'mobilePhone': instance.mobilePhone,
      'department': _departmentToJson(instance.department),
      'faculty': _facultyToJson(instance.faculty),
      'grade': _gradeToJson(instance.grade),
      'birthDate': instance.birthDate.toIso8601String(),
      'gender': instance.gender,
    };
