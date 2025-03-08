package bingol.campus.comment.core.exception;

import bingol.campus.security.exception.BusinessException;

public class CommentNotFoundException extends BusinessException {
    public CommentNotFoundException( ) {
        super("Yorum bulunamadı");
    }
}
