import 'package:json_annotation/json_annotation.dart';

part 'update_access_token_request_dto.g.dart';

@JsonSerializable()
class UpdateAccessTokenRequestDTO {
  final String refreshToken; // Yenileme tokenı
  final String ipAddress; // Kullanıcının talep sırasında kullandığı IP adresi
  final String deviceInfo; // Kullanıcının talep sırasında kullandığı cihaz bilgisi

  UpdateAccessTokenRequestDTO({
    required this.refreshToken,
    required this.ipAddress,
    required this.deviceInfo,
  });

  factory UpdateAccessTokenRequestDTO.fromJson(Map<String, dynamic> json) => _$UpdateAccessTokenRequestDTOFromJson(json);
  Map<String, dynamic> toJson() => _$UpdateAccessTokenRequestDTOToJson(this);
} 