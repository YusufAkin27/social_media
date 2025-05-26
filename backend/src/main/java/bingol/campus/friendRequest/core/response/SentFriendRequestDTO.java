package bingol.campus.friendRequest.core.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class SentFriendRequestDTO {
    private UUID requestId;            // Arkadaşlık isteği ID'si
    private String receiverPhotoUrl;   // Alıcının profil fotoğrafının URL'si
    private String receiverUsername;   // Alıcının kullanıcı adı
    private String receiverFullName;   // Alıcının tam adı
    private String sentAt;             // İsteğin gönderildiği tarih/saat (formatlanmış)
    private String status;             // İsteğin durumu (örn: PENDING, ACCEPTED, REJECTED)
    private long popularityScore;
}
