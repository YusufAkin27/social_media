package bingol.campus.student.core.response;

import bingol.campus.comment.core.response.CommentDTO;
import com.fasterxml.jackson.annotation.JsonFormat;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class HomePostDTO {
    private long postId;
    private long userId;
    private String username;
    private List<String> content;
    private String profilePhoto;
    private String description;
    private List<String>tagAPerson;
    private String location;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime createdAt;
    private String howMoneyMinutesAgo;
    private boolean isFollow;

    private long like;
    private long comment;
    private long popularityScore;


}
