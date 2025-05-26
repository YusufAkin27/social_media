package bingol.campus.friendRequest.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class UnauthorizedRequestException extends BusinessException {
    public UnauthorizedRequestException( ) {
        super("Bu arkadaşlık isteğine erişim yetkiniz yok.");
    }
}
