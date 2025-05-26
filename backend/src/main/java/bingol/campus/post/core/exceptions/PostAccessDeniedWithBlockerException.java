package bingol.campus.post.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class PostAccessDeniedWithBlockerException extends BusinessException {


    public PostAccessDeniedWithBlockerException( ) {
        super("Bu gönderiyi görüntüleme yetkiniz yok: Engelleme nedeniyle erişim engellendi.");
    }
}
