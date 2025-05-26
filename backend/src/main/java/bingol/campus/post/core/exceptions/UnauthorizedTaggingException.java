package bingol.campus.post.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class UnauthorizedTaggingException extends BusinessException {
    public UnauthorizedTaggingException(String taggedUsername) {
        super(taggedUsername + " kullanıcısını yalnızca takip ettiğiniz ya da sizi takip eden kişilerden seçebilirsiniz.");
    }
}
