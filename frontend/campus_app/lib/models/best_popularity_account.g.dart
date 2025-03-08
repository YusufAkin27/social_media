// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'best_popularity_account.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

BestPopularityAccount _$BestPopularityAccountFromJson(
        Map<String, dynamic> json) =>
    BestPopularityAccount(
      userId: (json['userId'] as num).toInt(),
      fullName: json['fullName'] as String,
      username: json['username'] as String,
      profilePhoto: json['profilePhoto'] as String,
      isFollow: json['isFollow'] as bool? ?? false,
      commonFriends: (json['commonFriends'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      followingCount: (json['followingCount'] as num).toInt(),
      followerCount: (json['followerCount'] as num).toInt(),
      postCount: (json['postCount'] as num).toInt(),
      isPrivate: json['isPrivate'] as bool? ?? false,
      popularityScore: (json['popularityScore'] as num).toInt(),
    );

Map<String, dynamic> _$BestPopularityAccountToJson(
        BestPopularityAccount instance) =>
    <String, dynamic>{
      'userId': instance.userId,
      'fullName': instance.fullName,
      'username': instance.username,
      'profilePhoto': instance.profilePhoto,
      'isFollow': instance.isFollow,
      'commonFriends': instance.commonFriends,
      'followingCount': instance.followingCount,
      'followerCount': instance.followerCount,
      'postCount': instance.postCount,
      'isPrivate': instance.isPrivate,
      'popularityScore': instance.popularityScore,
    };
