package bingol.campus.story.core.response;

import bingol.campus.story.entity.Story;
import lombok.AllArgsConstructor;
import lombok.Getter;

@Getter
@AllArgsConstructor
public class StoryScoreDTO {
    private Story story;
    private int score;
}
