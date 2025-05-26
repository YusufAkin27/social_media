package bingol.campus.story.core.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;
import java.util.UUID;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class FeatureStoryDTO {
    private UUID featureStoryId;
    private String coverPhoto;
    private String title;
    private List<StoryDTO>storyDTOS;
}
