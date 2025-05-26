package bingol.campus.friendRequest.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class AlreadyFollowingException extends BusinessException {
    public AlreadyFollowingException( ) {
        super("Bu kullanıcıyı zaten takip ediyorsunuz, arkadaşlık isteği gönderemezsiniz.");
    }
}
