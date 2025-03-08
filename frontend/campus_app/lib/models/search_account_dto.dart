import 'package:json_annotation/json_annotation.dart';

part 'search_account_dto.g.dart';

@JsonSerializable()
class SearchAccountDTO {
  final int id; // long türü Dart'ta int olarak temsil edilir
  final String? fullName; // Tam ad
  final String profilePhoto; // Profil fotoğrafı URL'si
  final String username; // Kullanıcı adı
  @JsonKey(defaultValue: false)
  final bool? isPrivate; // Hesap gizli mi?
  @JsonKey(defaultValue: false)
  final bool? isFollow; // Takip ediliyor mu?

  SearchAccountDTO({
    required this.id,
    this.fullName,
    required this.profilePhoto,
    required this.username,
    this.isPrivate,
    this.isFollow,
  });

  factory SearchAccountDTO.fromJson(Map<String, dynamic> json) => _$SearchAccountDTOFromJson(json);
  Map<String, dynamic> toJson() => _$SearchAccountDTOToJson(this);
} 