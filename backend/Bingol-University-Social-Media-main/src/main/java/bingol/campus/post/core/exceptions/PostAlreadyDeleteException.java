package bingol.campus.post.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class PostAlreadyDeleteException extends BusinessException {
    public PostAlreadyDeleteException( ) {
        super("Geçersiz işlem: Bu gönderi zaten silinmiş durumda.");
    }
}
