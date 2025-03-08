package bingol.campus.like.core.converter;

import bingol.campus.like.entity.Like;
import bingol.campus.post.core.response.LikeDetailsDTO;

public interface LikeConverter {
    LikeDetailsDTO toDetails(Like like);
}
