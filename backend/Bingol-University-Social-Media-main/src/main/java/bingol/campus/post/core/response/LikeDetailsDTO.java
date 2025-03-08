package bingol.campus.post.core.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class LikeDetailsDTO {
    private Long userId;
    private String username;
    private String profilePhoto;
}
