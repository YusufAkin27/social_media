package bingol.campus.post.core.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class CommentDetailsDTO {
    private Long userId;
    private String username;
    private String content;
    private LocalDateTime createdAt;
    private String howMoneyMinutesAgo;
}
