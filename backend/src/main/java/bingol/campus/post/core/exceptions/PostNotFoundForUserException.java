package bingol.campus.post.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class PostNotFoundForUserException extends BusinessException {
    public PostNotFoundForUserException( ) {
        super("Gönderi bulunamadı: Belirtilen gönderi mevcut değil veya size ait değil.");
    }
}
