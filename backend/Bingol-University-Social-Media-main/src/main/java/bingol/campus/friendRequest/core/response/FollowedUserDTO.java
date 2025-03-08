package bingol.campus.friendRequest.core.response;

import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class FollowedUserDTO {
    private long id;
    private String username;           // Kullanıcı adı
    private String fullName;           // Tam ad
    private String profilePhotoUrl;    // Profil fotoğrafı URL'si
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd")
    private LocalDate followedDate; // Takip edildiği tarih
    private boolean isActive;          // Takip ilişkisi aktif mi?
    private boolean isPrivate;
    private String bio;                // Kullanıcının biyografisi
    private int popularityScore;       // Kullanıcının popülerlik skoru
}
