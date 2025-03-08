package bingol.campus.friendRequest.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class SelfFriendRequestException extends BusinessException {
    public SelfFriendRequestException( ) {
        super("Kendinize arkadaşlık isteği gönderemezsiniz.");
    }
}
