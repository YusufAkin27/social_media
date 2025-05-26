package bingol.campus.like.core.converter;

import bingol.campus.like.entity.Like;
import bingol.campus.post.core.response.LikeDetailsDTO;
import org.springframework.stereotype.Component;

@Component
public class LikeConverterImpl implements LikeConverter {
    @Override
    public LikeDetailsDTO toDetails(Like like) {
        return LikeDetailsDTO.builder()
                .profilePhoto(like.getStudent().getProfilePhoto())
                .userId(like.getStudent().getId())
                .username(like.getStudent().getUsername())
                .build();
    }
}
