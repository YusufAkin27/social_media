// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'story_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

StoryDetails _$StoryDetailsFromJson(Map<String, dynamic> json) => StoryDetails(
      id: json['id'] as String,
      username: json['username'] as String,
      photoUrl: json['photoUrl'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      expiresAt: DateTime.parse(json['expiresAt'] as String),
      isActive: json['isActive'] as bool,
      likeCount: (json['likeCount'] as num).toInt(),
      comments: (json['comments'] as List<dynamic>)
          .map((e) => CommentDetailsDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      viewing: (json['viewing'] as List<dynamic>)
          .map((e) => SearchAccountDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      likes: (json['likes'] as List<dynamic>)
          .map((e) => LikeDetailsDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$StoryDetailsToJson(StoryDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'photoUrl': instance.photoUrl,
      'createdAt': instance.createdAt.toIso8601String(),
      'expiresAt': instance.expiresAt.toIso8601String(),
      'isActive': instance.isActive,
      'likeCount': instance.likeCount,
      'comments': instance.comments,
      'viewing': instance.viewing,
      'likes': instance.likes,
    };
