import 'package:json_annotation/json_annotation.dart';

part 'comment_details_dto.g.dart';

@JsonSerializable()
class CommentDetailsDTO {
  final int userId; // Long türü Dart'ta int olarak temsil edilir
  final String username; // Kullanıcı adı
  final String content; // Yorum içeriği
  @JsonKey(name: 'createdAt')
  final DateTime createdAt; // Oluşturulma tarihi
  final String howMoneyMinutesAgo; // Ne kadar önce

  CommentDetailsDTO({
    required this.userId,
    required this.username,
    required this.content,
    required this.createdAt,
    required this.howMoneyMinutesAgo,
  });

  factory CommentDetailsDTO.fromJson(Map<String, dynamic> json) => _$CommentDetailsDTOFromJson(json);
  Map<String, dynamic> toJson() => _$CommentDetailsDTOToJson(this);
} 