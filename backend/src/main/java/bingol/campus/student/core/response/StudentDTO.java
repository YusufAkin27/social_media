package bingol.campus.student.core.response;

import bingol.campus.student.entity.enums.Department;
import bingol.campus.student.entity.enums.Faculty;
import bingol.campus.student.entity.enums.Grade;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class StudentDTO {
    private long userId;
    private String firstName;           // Öğrencinin adı
    private String lastName;            // Öğrencinin soyadı
    private String tcIdentityNumber;    // TC Kimlik Numarası
    private String username;            // Kullanıcı adı
    private String email;               // E-posta adresi
    private String mobilePhone;         // Telefon numarası
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    private LocalDate birthDate;        // Doğum tarihi
    private Boolean gender;             // Cinsiyet (true: Erkek, false: Kadın)
    private Faculty faculty;            // Fakülte
    private Department department;      // Bölüm
    private Grade grade;                // Sınıf
    private String profilePhoto;        // Profil fotoğrafı URL veya dosya yolu
    private Boolean isActive;           // Hesap aktif mi?
    private Boolean isDeleted;          // Hesap silinmiş mi?
    private boolean isPrivate;          // Profil gizli mi?
    private String biography;           // Biyografi
    private int popularityScore;        // Popülerlik skoru

    // Takip ilişkileri
    private long follower;     // Takipçi listesi (U)
    private long following;    // Takip edilenler listesi (Sadece isim veya ID)
    private long block;

    // Arkadaşlık istekleri
    private long friendRequestsReceived; // Gelen arkadaşlık istekleri
    private long friendRequestsSent;     // Gönderilen arkadaşlık istekleri

    // İçerikler
    private long posts;         // Gönderi başlıkları veya içerikleri
    private long stories;       // Hikayeler (Başlıklar veya içerik)
    private long featuredStories; // Öne çıkan hikayeler

    // Etkileşimler
    private long likedContents; // Beğendiği içeriklerin başlıkları veya ID'leri
    private long comments;      // Yaptığı yorumların başlıkları veya içerikleri
}
