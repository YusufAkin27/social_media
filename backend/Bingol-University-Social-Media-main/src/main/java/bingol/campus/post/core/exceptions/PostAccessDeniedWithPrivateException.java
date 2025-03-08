package bingol.campus.post.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class PostAccessDeniedWithPrivateException extends BusinessException {
    public PostAccessDeniedWithPrivateException( ) {
        super("Bu gönderiyi görüntüleme yetkiniz yok: Gönderi sahibi özel bir hesaba sahip ve takip etmiyorsunuz.");
    }
}
