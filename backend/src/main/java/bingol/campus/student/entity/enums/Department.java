package bingol.campus.student.entity.enums;

public enum Department {
    // Diş Hekimliği Fakültesi
    DIS_HEKIMLIGI("Diş Hekimliği"),

    // Fen-Edebiyat Fakültesi
    ARAP_DILI_VE_EDEBIYATI("Arap Dili ve Edebiyatı"),
    COGRAFYA("Coğrafya"),
    FELSEFE("Felsefe"),
    INGILIZ_DILI_VE_EDEBIYATI("İngiliz Dili ve Edebiyatı"),
    INGILIZ_DILI_VE_EDEBIYATI_IO("İngiliz Dili ve Edebiyatı (İÖ)"),
    KURT_DILI_VE_EDEBIYATI("Kürt Dili ve Edebiyatı"),
    MATEMATIK("Matematik"),
    MOLEKULER_BIYOLOJI_VE_GENETIK("Moleküler Biyoloji ve Genetik"),
    PSIKOLOJI("Psikoloji"),
    SOSYAL_HIZMET("Sosyal Hizmet"),
    SOSYAL_HIZMET_IO("Sosyal Hizmet (İÖ)"),
    SOSYOLOJI("Sosyoloji"),
    TARIH("Tarih"),
    TARIH_IO("Tarih (İÖ)"),
    TURK_DILI_VE_EDEBIYATI("Türk Dili ve Edebiyatı"),
    TURK_DILI_VE_EDEBIYATI_IO("Türk Dili ve Edebiyatı (İÖ)"),
    ZAZA_DILI_VE_EDEBIYATI("Zaza Dili ve Edebiyatı"),

    // İktisadi ve İdari Bilimler Fakültesi
    IKTISAT("İktisat"),
    ISLETME("İşletme"),
    SIYASET_BILIMI_VE_KAMU_YONETIMI("Siyaset Bilimi ve Kamu Yönetimi"),

    // İslami İlimler Fakültesi
    ISLAMI_ILIMLER("İslami İlimler"),
    ISLAMI_ILIMLER_MTOK("İslami İlimler (M.T.O.K.)"),

    // Mühendislik-Mimarlık Fakültesi
    BILGISAYAR_MUHENDISLIGI("Bilgisayar Mühendisliği"),
    ELEKTRIK_ELEKTRONIK_MUHENDISLIGI("Elektrik-Elektronik Mühendisliği"),
    INSAAT_MUHENDISLIGI("İnşaat Mühendisliği"),
    MIMARLIK("Mimarlık"),

    // Sağlık Bilimleri Fakültesi
    BESLENME_VE_DIYETETIK("Beslenme ve Diyetetik"),
    HEMSIRELIK("Hemşirelik"),
    IS_SAGLIGI_VE_GUVENLIGI("İş Sağlığı ve Güvenliği"),
    SAGLIK_YONETIMI("Sağlık Yönetimi"),

    // Spor Bilimleri Fakültesi
    REKREASYON("Rekreasyon"),
    ANTRENORLUK_EGITIMI("Antrenörlük Eğitimi (Özel Yetenek)"),
    BEDEN_EGITIMI_VE_SPOR_OGRETMENLIGI("Beden Eğitimi ve Spor Öğretmenliği (Özel Yetenek)"),
    SPOR_YONETICILIGI("Spor Yöneticiliği (Özel Yetenek)"),

    // Veteriner Fakültesi
    VETERINER_FAKULTESI("Veteriner Fakültesi"),

    // Ziraat Fakültesi
    BAHCE_BITKILERI("Bahçe Bitkileri"),
    BITKI_KORUMA("Bitki Koruma"),
    BIYOSISTEM_MUHENDISLIGI("Biyosistem Mühendisliği"),
    PEYZAJ_MIMARLIGI("Peyzaj Mimarlığı"),

    // Ön Lisans Programları (Meslek Yüksekokulları) - Bingöl Sosyal Bilimler MYO
    ADALET("Adalet"),
    ASCILIK("Aşçılık"),
    ASCILIK_IO("Aşçılık (İÖ)"),
    BURO_YONETIMI_VE_YONETICI_ASISTANLIGI("Büro Yönetimi ve Yönetici Asistanlığı"),
    CAGRI_MERKEZI_HIZMETLERI("Çağrı Merkezi Hizmetleri"),
    E_TICARET_VE_PAZARLAMA("E-Ticaret ve Pazarlama"),
    HALKLA_ILISKILER_VE_TANITIM("Halkla İlişkiler ve Tanıtım"),
    IS_SAGLIGI_VE_GUVENLIGI_MY("İş Sağlığı ve Güvenliği"),
    ISLETME_YONETIMI("İşletme Yönetimi"),
    MALIYE("Maliye"),
    MEDYA_VE_ILETISIM("Medya ve İletişim"),
    MUHASEBE_VE_VERGI_UYGULAMALARI("Muhasebe ve Vergi Uygulamaları");

    private final String displayName;

    Department(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
