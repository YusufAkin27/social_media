package bingol.campus.post.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class InvalidPostRequestException extends BusinessException {
    public InvalidPostRequestException( ) {
        super("Gönderi içeriği boş olamaz.");
    }
}
