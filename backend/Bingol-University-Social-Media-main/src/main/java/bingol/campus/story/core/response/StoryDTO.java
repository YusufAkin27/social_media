package bingol.campus.story.core.response;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class StoryDTO {
    private UUID storyId;
    private String profilePhoto;
    private String username;
    private long userId;
    private String photo;
    private int score;
}
