package bingol.campus.post.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class PostNotFoundException extends BusinessException {
    public PostNotFoundException( ) {
        super("Gönderi bulunamadı");
    }
}
