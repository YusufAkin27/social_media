// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_account_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchAccountDTO _$SearchAccountDTOFromJson(Map<String, dynamic> json) =>
    SearchAccountDTO(
      id: (json['id'] as num).toInt(),
      fullName: json['fullName'] as String?,
      profilePhoto: json['profilePhoto'] as String,
      username: json['username'] as String,
    );

Map<String, dynamic> _$SearchAccountDTOToJson(SearchAccountDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'fullName': instance.fullName,
      'profilePhoto': instance.profilePhoto,
      'username': instance.username,
    };
