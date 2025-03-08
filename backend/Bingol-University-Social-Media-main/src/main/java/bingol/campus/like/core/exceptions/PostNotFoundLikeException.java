package bingol.campus.like.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class PostNotFoundLikeException extends BusinessException {
    public PostNotFoundLikeException( ) {
        super("Gönderide beğeniniz bulunamadı");
    }
}
