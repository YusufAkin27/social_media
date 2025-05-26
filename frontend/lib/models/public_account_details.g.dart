// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'public_account_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PublicAccountDetails _$PublicAccountDetailsFromJson(
        Map<String, dynamic> json) =>
    PublicAccountDetails(
      userId: (json['userId'] as num).toInt(),
      fullName: json['fullName'] as String,
      username: json['username'] as String,
      profilePhoto: json['profilePhoto'] as String,
      bio: json['bio'] as String,
      isFollow: json['isFollow'] as bool,
      commonFriends: (json['commonFriends'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      followingCount: (json['followingCount'] as num).toInt(),
      followerCount: (json['followerCount'] as num).toInt(),
      postCount: (json['postCount'] as num).toInt(),
      isPrivate: json['isPrivate'] as bool,
      popularityScore: (json['popularityScore'] as num).toInt(),
      posts: (json['posts'] as List<dynamic>)
          .map((e) => PostDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      stories: (json['stories'] as List<dynamic>)
          .map((e) => StoryDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
      featuredStories: (json['featuredStories'] as List<dynamic>)
          .map((e) => FeatureStoryDTO.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$PublicAccountDetailsToJson(
        PublicAccountDetails instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'fullName': instance.fullName,
      'username': instance.username,
      'profilePhoto': instance.profilePhoto,
      'bio': instance.bio,
      'isFollow': instance.isFollow,
      'commonFriends': instance.commonFriends,
      'followingCount': instance.followingCount,
      'followerCount': instance.followerCount,
      'postCount': instance.postCount,
      'isPrivate': instance.isPrivate,
      'popularityScore': instance.popularityScore,
      'posts': instance.posts,
      'stories': instance.stories,
      'featuredStories': instance.featuredStories,
    };
