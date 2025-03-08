import 'package:json_annotation/json_annotation.dart';

part 'token_response_dto.g.dart';

@JsonSerializable()
class TokenResponseDTO {
  final String accessToken; // Erişim token'ı
  final String refreshToken; // Yenileme token'ı

  TokenResponseDTO({
    required this.accessToken,
    required this.refreshToken,
  });

  factory TokenResponseDTO.fromJson(Map<String, dynamic> json) => _$TokenResponseDTOFromJson(json);
  Map<String, dynamic> toJson() => _$TokenResponseDTOToJson(this);
} 