// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_student_profile_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

UpdateStudentProfileRequest _$UpdateStudentProfileRequestFromJson(
        Map<String, dynamic> json) =>
    UpdateStudentProfileRequest(
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      mobilePhone: json['mobilePhone'] as String,
      username: json['username'] as String,
      department: $enumDecode(_$DepartmentEnumMap, json['department']),
      biography: json['biography'] as String,
      birthDate: DateTime.parse(json['birthDate'] as String),
      faculty: $enumDecode(_$FacultyEnumMap, json['faculty']),
      grade: $enumDecode(_$GradeEnumMap, json['grade']),
      gender: json['gender'] as bool?,
    );

Map<String, dynamic> _$UpdateStudentProfileRequestToJson(
        UpdateStudentProfileRequest instance) =>
    <String, dynamic>{
      'firstName': instance.firstName,
      'lastName': instance.lastName,
      'mobilePhone': instance.mobilePhone,
      'username': instance.username,
      'department': _$DepartmentEnumMap[instance.department]!,
      'biography': instance.biography,
      'birthDate': instance.birthDate.toIso8601String(),
      'faculty': _$FacultyEnumMap[instance.faculty]!,
      'grade': _$GradeEnumMap[instance.grade]!,
      'gender': instance.gender,
    };

const _$DepartmentEnumMap = {
  Department.DIS_HEKIMLIGI: 'DIS_HEKIMLIGI',
  Department.ARAP_DILI_VE_EDEBIYATI: 'ARAP_DILI_VE_EDEBIYATI',
  Department.COGRAFYA: 'COGRAFYA',
  Department.FELSEFE: 'FELSEFE',
  Department.INGILIZ_DILI_VE_EDEBIYATI: 'INGILIZ_DILI_VE_EDEBIYATI',
  Department.INGILIZ_DILI_VE_EDEBIYATI_IO: 'INGILIZ_DILI_VE_EDEBIYATI_IO',
  Department.KURT_DILI_VE_EDEBIYATI: 'KURT_DILI_VE_EDEBIYATI',
  Department.MATEMATIK: 'MATEMATIK',
  Department.MOLEKULER_BIYOLOJI_VE_GENETIK: 'MOLEKULER_BIYOLOJI_VE_GENETIK',
  Department.PSIKOLOJI: 'PSIKOLOJI',
  Department.SOSYAL_HIZMET: 'SOSYAL_HIZMET',
  Department.SOSYAL_HIZMET_IO: 'SOSYAL_HIZMET_IO',
  Department.SOSYOLOJI: 'SOSYOLOJI',
  Department.TARIH: 'TARIH',
  Department.TARIH_IO: 'TARIH_IO',
  Department.TURK_DILI_VE_EDEBIYATI: 'TURK_DILI_VE_EDEBIYATI',
  Department.TURK_DILI_VE_EDEBIYATI_IO: 'TURK_DILI_VE_EDEBIYATI_IO',
  Department.ZAZA_DILI_VE_EDEBIYATI: 'ZAZA_DILI_VE_EDEBIYATI',
  Department.IKTISAT: 'IKTISAT',
  Department.ISLETME: 'ISLETME',
  Department.SIYASET_BILIMI_VE_KAMU_YONETIMI: 'SIYASET_BILIMI_VE_KAMU_YONETIMI',
  Department.ISLAMI_ILIMLER: 'ISLAMI_ILIMLER',
  Department.ISLAMI_ILIMLER_MTOK: 'ISLAMI_ILIMLER_MTOK',
  Department.BILGISAYAR_MUHENDISLIGI: 'BILGISAYAR_MUHENDISLIGI',
  Department.ELEKTRIK_ELEKTRONIK_MUHENDISLIGI:
      'ELEKTRIK_ELEKTRONIK_MUHENDISLIGI',
  Department.INSAAT_MUHENDISLIGI: 'INSAAT_MUHENDISLIGI',
  Department.MIMARLIK: 'MIMARLIK',
  Department.BESLENME_VE_DIYETETIK: 'BESLENME_VE_DIYETETIK',
  Department.HEMSIRELIK: 'HEMSIRELIK',
  Department.IS_SAGLIGI_VE_GUVENLIGI: 'IS_SAGLIGI_VE_GUVENLIGI',
  Department.SAGLIK_YONETIMI: 'SAGLIK_YONETIMI',
  Department.REKREASYON: 'REKREASYON',
  Department.ANTRENORLUK_EGITIMI: 'ANTRENORLUK_EGITIMI',
  Department.BEDEN_EGITIMI_VE_SPOR_OGRETMENLIGI:
      'BEDEN_EGITIMI_VE_SPOR_OGRETMENLIGI',
  Department.SPOR_YONETICILIGI: 'SPOR_YONETICILIGI',
  Department.VETERINER_FAKULTESI: 'VETERINER_FAKULTESI',
  Department.BAHCE_BITKILERI: 'BAHCE_BITKILERI',
  Department.BITKI_KORUMA: 'BITKI_KORUMA',
  Department.BIYOSISTEM_MUHENDISLIGI: 'BIYOSISTEM_MUHENDISLIGI',
  Department.PEYZAJ_MIMARLIGI: 'PEYZAJ_MIMARLIGI',
  Department.ADALET: 'ADALET',
  Department.ASCILIK: 'ASCILIK',
  Department.ASCILIK_IO: 'ASCILIK_IO',
  Department.BURO_YONETIMI_VE_YONETICI_ASISTANLIGI:
      'BURO_YONETIMI_VE_YONETICI_ASISTANLIGI',
  Department.CAGRI_MERKEZI_HIZMETLERI: 'CAGRI_MERKEZI_HIZMETLERI',
  Department.E_TICARET_VE_PAZARLAMA: 'E_TICARET_VE_PAZARLAMA',
  Department.HALKLA_ILISKILER_VE_TANITIM: 'HALKLA_ILISKILER_VE_TANITIM',
  Department.IS_SAGLIGI_VE_GUVENLIGI_MY: 'IS_SAGLIGI_VE_GUVENLIGI_MY',
  Department.ISLETME_YONETIMI: 'ISLETME_YONETIMI',
  Department.MALIYE: 'MALIYE',
  Department.MEDYA_VE_ILETISIM: 'MEDYA_VE_ILETISIM',
  Department.MUHASEBE_VE_VERGI_UYGULAMALARI: 'MUHASEBE_VE_VERGI_UYGULAMALARI',
  Department.DEFAULT: 'DEFAULT',
};

const _$FacultyEnumMap = {
  Faculty.DIS_HEKIMLIGI: 'DIS_HEKIMLIGI',
  Faculty.FEN_EDEBIYAT: 'FEN_EDEBIYAT',
  Faculty.FIZIK_TEDAVI: 'FIZIK_TEDAVI',
  Faculty.IKTISADI_IDARI: 'IKTISADI_IDARI',
  Faculty.ISLAMI_ILIMLER: 'ISLAMI_ILIMLER',
  Faculty.MUHENDISLIK_MIMARLIK: 'MUHENDISLIK_MIMARLIK',
  Faculty.SAGLIK_BILIMLERI: 'SAGLIK_BILIMLERI',
  Faculty.SPOR_BILIMLERI: 'SPOR_BILIMLERI',
  Faculty.VETERINER: 'VETERINER',
  Faculty.ZIRAAT: 'ZIRAAT',
  Faculty.MYO: 'MYO',
  Faculty.DEFAULT: 'DEFAULT',
};

const _$GradeEnumMap = {
  Grade.HAZIRLIK: 'HAZIRLIK',
  Grade.BIRINCI_SINIF: 'BIRINCI_SINIF',
  Grade.IKI_SINIF: 'IKI_SINIF',
  Grade.UCUNCU_SINIF: 'UCUNCU_SINIF',
  Grade.DORDUNCU_SINIF: 'DORDUNCU_SINIF',
  Grade.MEZUN: 'MEZUN',
  Grade.YUKSEK_LISANS_BIRINCI: 'YUKSEK_LISANS_BIRINCI',
  Grade.YUKSEK_LISANS_IKINCI: 'YUKSEK_LISANS_IKINCI',
  Grade.YUKSEK_LISANS_MEZUN: 'YUKSEK_LISANS_MEZUN',
  Grade.DOKTORA_BIRINCI: 'DOKTORA_BIRINCI',
  Grade.DOKTORA_IKINCI: 'DOKTORA_IKINCI',
  Grade.DOKTORA_UCUNCU: 'DOKTORA_UCUNCU',
  Grade.DOKTORA_MEZUN: 'DOKTORA_MEZUN',
  Grade.DEFAULT: 'DEFAULT',
};
