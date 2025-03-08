package bingol.campus.post.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class PostNotIsActiveException extends BusinessException {
    public PostNotIsActiveException( ) {
        super("Gönderi aktif değil");
    }
}
