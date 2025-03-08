import 'package:json_annotation/json_annotation.dart';

part 'block_user_dto.g.dart';

@JsonSerializable()
class BlockUserDTO {
  final String username;
  final String firstName;
  final String lastName;

  @JsonKey(name: 'blockDate')
  final DateTime blockDate;

  final String profilePhoto;

  BlockUserDTO({
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.blockDate,
    required this.profilePhoto,
  });

  factory BlockUserDTO.fromJson(Map<String, dynamic> json) => _$BlockUserDTOFromJson(json);
  Map<String, dynamic> toJson() => _$BlockUserDTOToJson(this);
} 