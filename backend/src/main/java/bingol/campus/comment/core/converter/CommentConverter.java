package bingol.campus.comment.core.converter;

import bingol.campus.comment.core.response.CommentDTO;
import bingol.campus.comment.entity.Comment;
import bingol.campus.post.core.response.CommentDetailsDTO;

public interface CommentConverter{

    CommentDTO toDto(Comment comment);
    CommentDetailsDTO toDetails(Comment comment);
}
