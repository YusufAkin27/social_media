class StudentModel {
  final String firstName;
  final String lastName;
  final String username;
  final String password;
  final String email;
  final String mobilePhone;
  final String? department;
  final String? faculty;
  final String? grade;
  final String birthDate;
  final bool gender;

  StudentModel({
    required this.firstName,
    required this.lastName,
    required this.username,
    required this.password,
    required this.email,
    required this.mobilePhone,
    this.department,
    this.faculty,
    this.grade,
    required this.birthDate,
    required this.gender,
  });

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'username': username,
      'password': password,
      'email': email,
      'mobilePhone': mobilePhone,
      'department': department,
      'faculty': faculty,
      'grade': grade,
      'birthDate': birthDate,
      'gender': gender,
    };
  }
} 