import 'package:json_annotation/json_annotation.dart';

part 'suggest_user_request.g.dart';

@JsonSerializable()
class SuggestUserRequest {
  final String username;
  final String? profilePhotoUrl;
  
  // Optional fields for better UI display
  @JsonKey(defaultValue: false)
  final bool? isFollowing;
  final String? fullName;
  final String? department;
  final int? mutualConnections;

  SuggestUserRequest({
    required this.username,
    this.profilePhotoUrl,
    this.isFollowing,
    this.fullName,
    this.department,
    this.mutualConnections,
  });

  factory SuggestUserRequest.fromJson(Map<String, dynamic> json) => _$SuggestUserRequestFromJson(json);
  
  Map<String, dynamic> toJson() => _$SuggestUserRequestToJson(this);
} 