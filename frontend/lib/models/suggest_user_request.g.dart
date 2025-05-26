// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'suggest_user_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SuggestUserRequest _$SuggestUserRequestFromJson(Map<String, dynamic> json) =>
    SuggestUserRequest(
      username: json['username'] as String,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      isFollowing: json['isFollowing'] as bool? ?? false,
      fullName: json['fullName'] as String?,
      department: json['department'] as String?,
      mutualConnections: (json['mutualConnections'] as num?)?.toInt(),
    );

Map<String, dynamic> _$SuggestUserRequestToJson(SuggestUserRequest instance) =>
    <String, dynamic>{
      'username': instance.username,
      'profilePhotoUrl': instance.profilePhotoUrl,
      'isFollowing': instance.isFollowing,
      'fullName': instance.fullName,
      'department': instance.department,
      'mutualConnections': instance.mutualConnections,
    };
