import 'package:json_annotation/json_annotation.dart';

part 'access_token_response.g.dart';

@JsonSerializable()
class AccessTokenResponse {
  final String accessToken; // Erişim token'ı

  AccessTokenResponse({
    required this.accessToken,
  });

  factory AccessTokenResponse.fromJson(Map<String, dynamic> json) => _$AccessTokenResponseFromJson(json);
  Map<String, dynamic> toJson() => _$AccessTokenResponseToJson(this);
} 