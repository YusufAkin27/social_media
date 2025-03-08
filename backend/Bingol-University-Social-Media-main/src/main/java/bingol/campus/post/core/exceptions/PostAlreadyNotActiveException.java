package bingol.campus.post.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class PostAlreadyNotActiveException extends BusinessException {
    public PostAlreadyNotActiveException( ) {
        super("Gönderi pasif durumda: Silinmiş veya devre dışı bırakılmış bir gönderiyi silemezsiniz.");
    }
}
