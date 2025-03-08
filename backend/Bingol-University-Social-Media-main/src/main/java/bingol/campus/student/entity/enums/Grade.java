package bingol.campus.student.entity.enums;

public enum Grade {
    HAZIRLIK("Hazırlık"),
    BIRINCI_SINIF("1. Sınıf"),
    IKI_SINIF("2. Sınıf"),
    UCUNCU_SINIF("3. Sınıf"),
    DORDUNCU_SINIF("4. Sınıf"),
    MEZUN("Mezun"),
    YUKSEK_LISANS_BIRINCI("Yüksek Lisans 1. Sınıf"),
    YUKSEK_LISANS_IKINCI("Yüksek Lisans 2. Sınıf"),
    YUKSEK_LISANS_MEZUN("Yüksek Lisans Mezunu"),
    DOKTORA_BIRINCI("Doktora 1. Sınıf"),
    DOKTORA_IKINCI("Doktora 2. Sınıf"),
    DOKTORA_UCUNCU("Doktora 3. Sınıf"),
    DOKTORA_MEZUN("Doktora Mezunu");

    private final String displayName;

    Grade(String displayName) {
        this.displayName = displayName;
    }

    public String getDisplayName() {
        return displayName;
    }
}
