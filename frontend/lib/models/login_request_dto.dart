import 'package:json_annotation/json_annotation.dart';

part 'login_request_dto.g.dart';

@JsonSerializable()
class LoginRequestDTO {
  final String username; // Kullanıcı numarası
  final String password; // Kullanıcı şifresi
  final String ipAddress; // Kullanıcının giriş yaptığı IP adresi
  final String deviceInfo; // Kullanıcının giriş yaptığı cihaz bilgisi

  LoginRequestDTO({
    required this.username,
    required this.password,
    required this.ipAddress,
    required this.deviceInfo,
  });

  factory LoginRequestDTO.fromJson(Map<String, dynamic> json) => _$LoginRequestDTOFromJson(json);
  Map<String, dynamic> toJson() => _$LoginRequestDTOToJson(this);
} 