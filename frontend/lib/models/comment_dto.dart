import 'package:json_annotation/json_annotation.dart';

part 'comment_dto.g.dart';

@JsonSerializable()
class CommentDTO {
  final String id; // UUID'yi String olarak tutuyoruz
  final String username;
  final String profilePhoto;
  final String postId; // UUID'yi String olarak tutuyoruz
  final String content;
  final String? storyId; // UUID'yi String olarak tutuyoruz, nullable
  final String howMoneyMinutesAgo;
  final DateTime createdAt;

  CommentDTO({
    required this.id,
    required this.username,
    required this.profilePhoto,
    required this.postId,
    required this.content,
    this.storyId,
    required this.howMoneyMinutesAgo,
    required this.createdAt,
  });

  factory CommentDTO.fromJson(Map<String, dynamic> json) => _$CommentDTOFromJson(json);
  Map<String, dynamic> toJson() => _$CommentDTOToJson(this);
} 