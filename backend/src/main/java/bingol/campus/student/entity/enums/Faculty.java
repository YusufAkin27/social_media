package bingol.campus.student.entity.enums;

import java.util.*;

public enum Faculty {
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
    MYO("Meslek Yüksekokulları");


    private final String displayName;

    Faculty(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }

    // Fakültelere ait bölümleri içeren statik harita
    private static final Map<Faculty, List<Department>> facultyDepartments = new HashMap<>();

    static {
        facultyDepartments.put(DIS_HEKIMLIGI, List.of(Department.DIS_HEKIMLIGI));
        facultyDepartments.put(FEN_EDEBIYAT, List.of(
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
        ));
        facultyDepartments.put(IKTISADI_IDARI, List.of(
                Department.IKTISAT,
                Department.ISLETME,
                Department.SIYASET_BILIMI_VE_KAMU_YONETIMI
        ));
        facultyDepartments.put(ISLAMI_ILIMLER, List.of(
                Department.ISLAMI_ILIMLER,
                Department.ISLAMI_ILIMLER_MTOK
        ));
        facultyDepartments.put(MUHENDISLIK_MIMARLIK, List.of(
                Department.BILGISAYAR_MUHENDISLIGI,
                Department.ELEKTRIK_ELEKTRONIK_MUHENDISLIGI,
                Department.INSAAT_MUHENDISLIGI,
                Department.MIMARLIK
        ));
        facultyDepartments.put(SAGLIK_BILIMLERI, List.of(
                Department.BESLENME_VE_DIYETETIK,
                Department.HEMSIRELIK,
                Department.IS_SAGLIGI_VE_GUVENLIGI,
                Department.SAGLIK_YONETIMI
        ));
        facultyDepartments.put(SPOR_BILIMLERI, List.of(
                Department.REKREASYON,
                Department.ANTRENORLUK_EGITIMI,
                Department.BEDEN_EGITIMI_VE_SPOR_OGRETMENLIGI,
                Department.SPOR_YONETICILIGI
        ));
        facultyDepartments.put(VETERINER, List.of(Department.VETERINER_FAKULTESI));
        facultyDepartments.put(ZIRAAT, List.of(
                Department.BAHCE_BITKILERI,
                Department.BITKI_KORUMA,
                Department.BIYOSISTEM_MUHENDISLIGI,
                Department.PEYZAJ_MIMARLIGI
        ));
        facultyDepartments.put(MYO, List.of(
                Department.ADALET, Department.ASCILIK, Department.ASCILIK_IO,
                Department.BURO_YONETIMI_VE_YONETICI_ASISTANLIGI, Department.CAGRI_MERKEZI_HIZMETLERI,
                Department.E_TICARET_VE_PAZARLAMA, Department.HALKLA_ILISKILER_VE_TANITIM,
                Department.IS_SAGLIGI_VE_GUVENLIGI_MY, Department.ISLETME_YONETIMI,
                Department.MALIYE, Department.MEDYA_VE_ILETISIM, Department.MUHASEBE_VE_VERGI_UYGULAMALARI
        ));
    }


    public List<Department> getDepartments() {
        return facultyDepartments.getOrDefault(this, Collections.emptyList());
    }
}
