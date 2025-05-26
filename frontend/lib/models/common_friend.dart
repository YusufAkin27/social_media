import 'package:json_annotation/json_annotation.dart';

part 'common_friend.g.dart';

@JsonSerializable()
class CommonFriend {
  final String username; // Ortak arkadaşın kullanıcı adı
  final String profilePhoto; // Ortak arkadaşın profil fotoğrafı

  CommonFriend({
    required this.username,
    required this.profilePhoto,
  });

  factory CommonFriend.fromJson(Map<String, dynamic> json) => _$CommonFriendFromJson(json);
  Map<String, dynamic> toJson() => _$CommonFriendToJson(this);
} 