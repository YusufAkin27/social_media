// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_account_dto.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

SearchAccountDTO _$SearchAccountDTOFromJson(Map<String, dynamic> json) =>
    SearchAccountDTO(
      id: (json['id'] as num).toInt(),
      username: json['username'] as String,
      fullName: json['fullName'] as String?,
      profilePhoto: json['profilePhoto'] as String,
      isPrivate: json['isPrivate'] as bool?,
      isFollow: json['isFollow'] as bool?,
    );

Map<String, dynamic> _$SearchAccountDTOToJson(SearchAccountDTO instance) =>
    <String, dynamic>{
      'id': instance.id,
      'username': instance.username,
      'fullName': instance.fullName,
      'profilePhoto': instance.profilePhoto,
      'isPrivate': instance.isPrivate,
      'isFollow': instance.isFollow,
    };
