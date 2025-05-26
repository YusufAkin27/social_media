package bingol.campus.friendRequest.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class AlreadySentRequestException extends BusinessException {
    public AlreadySentRequestException( ) {
        super("Bu kullanıcıya zaten arkadaşlık isteği gönderdiniz.");
    }
}
