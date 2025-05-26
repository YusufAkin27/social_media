import 'department.dart';

enum Faculty {
  DIS_HEKIMLIGI("Diş Hekimliği Fakültesi"),
  FEN_EDEBIYAT("Fen Edebiyat Fakültesi"),
  FIZIK_TEDAVI("Fizik Tedavi ve Rehabilitasyon Fakültesi"),
  IKTISADI_IDARI("İktisadi ve İdari Bilimler Fakültesi"),
  ISLAMI_ILIMLER("İslami İlimler Fakültesi"),
  MUHENDISLIK_MIMARLIK("Mühendislik ve Mimarlık Fakültesi"),
  SAGLIK_BILIMLERI("Sağlık Bilimleri Fakültesi"),
  SPOR_BILIMLERI("Spor Bilimleri Fakültesi"),
  VETERINER("Veteriner Fakültesi"),
  ZIRAAT("Ziraat Fakültesi"),
  MYO("Meslek Yüksekokulları"),
  DEFAULT("Seçiniz");

  final String displayName;
  const Faculty(this.displayName);

  List<Department> get departments => _getDepartments();

  List<Department> _getDepartments() {
    switch (this) {
      case Faculty.DIS_HEKIMLIGI:
        return [Department.DIS_HEKIMLIGI];
      case Faculty.FEN_EDEBIYAT:
        return [
          Department.ARAP_DILI_VE_EDEBIYATI,
          Department.COGRAFYA,
          Department.FELSEFE,
          Department.INGILIZ_DILI_VE_EDEBIYATI,
          Department.INGILIZ_DILI_VE_EDEBIYATI_IO,
          Department.KURT_DILI_VE_EDEBIYATI,
          Department.MATEMATIK,
          Department.MOLEKULER_BIYOLOJI_VE_GENETIK,
          Department.PSIKOLOJI,
          Department.SOSYAL_HIZMET,
          Department.SOSYAL_HIZMET_IO,
          Department.SOSYOLOJI,
          Department.TARIH,
          Department.TARIH_IO,
          Department.TURK_DILI_VE_EDEBIYATI,
          Department.TURK_DILI_VE_EDEBIYATI_IO,
          Department.ZAZA_DILI_VE_EDEBIYATI
        ];
      case Faculty.IKTISADI_IDARI:
        return [
          Department.IKTISAT,
          Department.ISLETME,
          Department.SIYASET_BILIMI_VE_KAMU_YONETIMI
        ];
      case Faculty.ISLAMI_ILIMLER:
        return [
          Department.ISLAMI_ILIMLER,
          Department.ISLAMI_ILIMLER_MTOK
        ];
      case Faculty.MUHENDISLIK_MIMARLIK:
        return [
          Department.BILGISAYAR_MUHENDISLIGI,
          Department.ELEKTRIK_ELEKTRONIK_MUHENDISLIGI,
          Department.INSAAT_MUHENDISLIGI,
          Department.MIMARLIK
        ];
      case Faculty.SAGLIK_BILIMLERI:
        return [
          Department.BESLENME_VE_DIYETETIK,
          Department.HEMSIRELIK,
          Department.IS_SAGLIGI_VE_GUVENLIGI,
          Department.SAGLIK_YONETIMI
        ];
      case Faculty.SPOR_BILIMLERI:
        return [
          Department.REKREASYON,
          Department.ANTRENORLUK_EGITIMI,
          Department.BEDEN_EGITIMI_VE_SPOR_OGRETMENLIGI,
          Department.SPOR_YONETICILIGI
        ];
      case Faculty.VETERINER:
        return [Department.VETERINER_FAKULTESI];
      case Faculty.ZIRAAT:
        return [
          Department.BAHCE_BITKILERI,
          Department.BITKI_KORUMA,
          Department.BIYOSISTEM_MUHENDISLIGI,
          Department.PEYZAJ_MIMARLIGI
        ];
      case Faculty.MYO:
        return [
          Department.ADALET,
          Department.ASCILIK,
          Department.ASCILIK_IO,
          Department.BURO_YONETIMI_VE_YONETICI_ASISTANLIGI,
          Department.CAGRI_MERKEZI_HIZMETLERI,
          Department.E_TICARET_VE_PAZARLAMA,
          Department.HALKLA_ILISKILER_VE_TANITIM,
          Department.IS_SAGLIGI_VE_GUVENLIGI_MY,
          Department.ISLETME_YONETIMI,
          Department.MALIYE,
          Department.MEDYA_VE_ILETISIM,
          Department.MUHASEBE_VE_VERGI_UYGULAMALARI
        ];
      default:
        return [];
    }
  }
} 