import 'package:json_annotation/json_annotation.dart';

part 'search_account_dto.g.dart';

@JsonSerializable()
class SearchAccountDTO {
  final int id;
  final String username;
  final String? fullName;
  final String profilePhoto;
  final bool? isPrivate;
  final bool? isFollow;

  SearchAccountDTO({
    required this.id,
    required this.username,
    this.fullName,
    required this.profilePhoto,
    this.isPrivate,
    this.isFollow,
  });

  // Custom FromJson constructor to handle type conversion issues
  factory SearchAccountDTO.fromJson(Map<String, dynamic> json) {
    // Safely convert numeric types
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

    // Handle boolean conversions
    bool? safeBoolParse(dynamic value) {
      if (value == null) return null;
      if (value is bool) return value;
      if (value is int) return value == 1;
      if (value is String) {
        if (value.toLowerCase() == 'true' || value == '1') return true;
        if (value.toLowerCase() == 'false' || value == '0') return false;
      }
      return null;
    }

    return SearchAccountDTO(
      id: safeIntParse(json['id']),
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String?,
      profilePhoto: json['profilePhoto'] as String? ?? '',
      isPrivate: safeBoolParse(json['isPrivate']),
      isFollow: safeBoolParse(json['isFollow']),
    );
  }

  Map<String, dynamic> toJson() => _$SearchAccountDTOToJson(this);
} 