import 'package:json_annotation/json_annotation.dart';

part 'follower.g.dart';

@JsonSerializable()
class Follower {
  final int id;
  final String username;
  final String fullName;
  final String? profilePhotoUrl;
  
  @JsonKey(name: 'followedDate')
  final DateTime followedDate;
  
  final bool isActive;
  final bool isPrivate;
  final String? bio;
  final int popularityScore;
  
  @JsonKey(name: 'isFollowing', defaultValue: false)
  final bool? isFollowing;

  Follower({
    required this.id,
    required this.username,
    required this.fullName,
    this.profilePhotoUrl,
    required this.followedDate,
    required this.isActive,
    required this.isPrivate,
    this.bio,
    required this.popularityScore,
    this.isFollowing,
  });

  factory Follower.fromJson(Map<String, dynamic> json) => _$FollowerFromJson(json);
  Map<String, dynamic> toJson() => _$FollowerToJson(this);
} 