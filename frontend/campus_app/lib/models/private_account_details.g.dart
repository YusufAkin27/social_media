// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'private_account_details.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

PrivateAccountDetails _$PrivateAccountDetailsFromJson(
        Map<String, dynamic> json) =>
    PrivateAccountDetails(
      id: (json['id'] as num).toInt(),
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
      isSentRequest: json['isSentRequest'] as bool,
      isPrivate: json['isPrivate'] as bool,
      popularityScore: (json['popularityScore'] as num).toInt(),
    );

Map<String, dynamic> _$PrivateAccountDetailsToJson(
        PrivateAccountDetails instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'profilePhoto': instance.profilePhoto,
      'bio': instance.bio,
      'isFollow': instance.isFollow,
      'commonFriends': instance.commonFriends,
      'followingCount': instance.followingCount,
      'followerCount': instance.followerCount,
      'postCount': instance.postCount,
      'isSentRequest': instance.isSentRequest,
      'isPrivate': instance.isPrivate,
      'popularityScore': instance.popularityScore,
    };
