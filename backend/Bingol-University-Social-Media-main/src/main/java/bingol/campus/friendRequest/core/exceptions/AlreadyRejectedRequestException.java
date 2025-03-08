package bingol.campus.friendRequest.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class AlreadyRejectedRequestException extends BusinessException {
    public AlreadyRejectedRequestException( ) {
        super("Bu arkadaşlık isteği zaten reddedildi.");
    }
}
