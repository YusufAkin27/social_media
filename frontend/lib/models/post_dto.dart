import 'package:json_annotation/json_annotation.dart';

part 'post_dto.g.dart';

@JsonSerializable()
class PostDTO {
  final String postId; // UUID'ler String olarak temsil edilir
  final int userId; // long türü Dart'ta int olarak temsil edilir
  final String username; // Kullanıcı adı
  final List<String> content; // İçerik
  final String profilePhoto; // Profil fotoğrafı URL'si
  final String description; // Açıklama
  final List<String> tagAPerson; // Kişi etiketleme
  final String location; // Konum
  @JsonKey(name: 'createdAt')
  final DateTime createdAt; // Oluşturulma tarihi
  final String howMoneyMinutesAgo; // Ne kadar önce

  final int like; // Beğeni sayısı
  final int comment; // Yorum sayısı
  final int popularityScore; // Popülerlik skoru
  
  bool isLiked; // Kullanıcı tarafından beğenilme durumu

  PostDTO({
    required this.postId,
    required this.userId,
    required this.username,
    required this.content,
    required this.profilePhoto,
    required this.description,
    required this.tagAPerson,
    required this.location,
    required this.createdAt,
    required this.howMoneyMinutesAgo,
    required this.like,
    required this.comment,
    required this.popularityScore,
    this.isLiked = false,
  });

  // Custom FromJson constructor to handle DateTime parsing correctly
  factory PostDTO.fromJson(Map<String, dynamic> json) {
    // Handle different types of content data
    List<String> contentList = [];
    if (json['content'] != null) {
      if (json['content'] is List) {
        contentList = (json['content'] as List)
            .map((item) => item?.toString() ?? '')
            .where((item) => item.isNotEmpty)
            .toList();
      } else if (json['content'] is String) {
        String contentStr = json['content'] as String;
        if (contentStr.isNotEmpty) {
          contentList = [contentStr];
        }
      }
    }

    // Handle DateTime parsing with different formats
    DateTime parsedDate;
    try {
      if (json['createdAt'] is String) {
        String dateStr = json['createdAt'] as String;
        if (dateStr.contains('T')) {
          // ISO format like "2023-01-01T12:00:00"
          parsedDate = DateTime.parse(dateStr);
        } else {
          // Format like "2025-03-07 02:53:04"
          parsedDate = DateTime.parse(dateStr.replaceAll(' ', 'T'));
        }
      } else {
        // Default to current time if no valid date
        parsedDate = DateTime.now();
      }
    } catch (e) {
      print('Date parsing error for ${json['createdAt']}: $e');
      parsedDate = DateTime.now();
    }

    // Safely convert numeric types, handling potential string-to-int conversion
    int safeIntParse(dynamic value, {int defaultValue = 0}) {
      if (value == null) return defaultValue;
      if (value is int) return value;
      if (value is String) {
        try {
          return int.parse(value);
        } catch (e) {
          print('Int parsing error for $value: $e');
          return defaultValue;
        }
      }
      return defaultValue;
    }

    return PostDTO(
      postId: json['postId'] as String? ?? '',
      userId: safeIntParse(json['userId']),
      username: json['username'] as String? ?? '',
      content: contentList,
      profilePhoto: json['profilePhoto'] as String? ?? '',
      description: json['description'] as String? ?? '',
      tagAPerson: (json['tagAPerson'] as List?)
              ?.map((e) => e as String)
              .toList() ??
          [],
      location: json['location'] as String? ?? '',
      createdAt: parsedDate,
      howMoneyMinutesAgo: json['howMoneyMinutesAgo'] as String? ?? '',
      like: safeIntParse(json['like']),
      comment: safeIntParse(json['comment']),
      popularityScore: safeIntParse(json['popularityScore']),
      isLiked: json['isLiked'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => _$PostDTOToJson(this);
  
  // Add a copyWith method to create a new instance with modified properties
  PostDTO copyWith({
    String? postId,
    int? userId,
    String? username,
    List<String>? content,
    String? profilePhoto,
    String? description,
    List<String>? tagAPerson,
    String? location,
    DateTime? createdAt,
    String? howMoneyMinutesAgo,
    int? like,
    int? comment,
    int? popularityScore,
    bool? isLiked,
  }) {
    return PostDTO(
      postId: postId ?? this.postId,
      userId: userId ?? this.userId,
      username: username ?? this.username,
      content: content ?? this.content,
      profilePhoto: profilePhoto ?? this.profilePhoto,
      description: description ?? this.description,
      tagAPerson: tagAPerson ?? this.tagAPerson,
      location: location ?? this.location,
      createdAt: createdAt ?? this.createdAt,
      howMoneyMinutesAgo: howMoneyMinutesAgo ?? this.howMoneyMinutesAgo,
      like: like ?? this.like,
      comment: comment ?? this.comment,
      popularityScore: popularityScore ?? this.popularityScore,
      isLiked: isLiked ?? this.isLiked,
    );
  }
} 