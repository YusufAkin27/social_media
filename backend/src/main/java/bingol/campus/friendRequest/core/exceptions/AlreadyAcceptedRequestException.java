package bingol.campus.friendRequest.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class AlreadyAcceptedRequestException extends BusinessException {
    public AlreadyAcceptedRequestException( ) {
        super("Bu arkadaşlık isteği zaten kabul edildi.");
    }
}
