package bingol.campus.comment.core.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;


import java.time.LocalDateTime;
import java.util.UUID;

@AllArgsConstructor
@NoArgsConstructor
@Data
@Builder
public class CommentDTO {
    private UUID id;
    private String username;
    private String profilePhoto;

    private UUID postId;

    private String content;
    private UUID storyId;

    private String howMoneyMinutesAgo;
    private LocalDateTime createdAt;
}
