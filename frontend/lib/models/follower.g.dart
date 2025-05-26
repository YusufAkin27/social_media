// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'follower.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Follower _$FollowerFromJson(Map<String, dynamic> json) => Follower(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      fullName: json['fullName'] as String,
      profilePhotoUrl: json['profilePhotoUrl'] as String?,
      followedDate: DateTime.parse(json['followedDate'] as String),
      isActive: json['isActive'] as bool,
      isPrivate: json['isPrivate'] as bool,
      bio: json['bio'] as String?,
      popularityScore: (json['popularityScore'] as num).toInt(),
      isFollowing: json['isFollowing'] as bool? ?? false,
    );

Map<String, dynamic> _$FollowerToJson(Follower instance) => <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'fullName': instance.fullName,
      'profilePhotoUrl': instance.profilePhotoUrl,
      'followedDate': instance.followedDate.toIso8601String(),
      'isActive': instance.isActive,
      'isPrivate': instance.isPrivate,
      'bio': instance.bio,
      'popularityScore': instance.popularityScore,
      'isFollowing': instance.isFollowing,
    };
