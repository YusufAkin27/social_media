package bingol.campus.security.dto;

import lombok.Data;

@Data
public class UpdateAccessTokenRequestDTO {
    private String refreshToken; // Yenileme tokenı
    private String ipAddress;    // Kullanıcının talep sırasında kullandığı IP adresi
    private String deviceInfo;   // Kullanıcının talep sırasında kullandığı cihaz bilgisi
}
