package bingol.campus.friendRequest.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class FriendRequestNotFoundException extends BusinessException {
    public FriendRequestNotFoundException( ) {
        super("Arkadaşlık isteği bulunamadı");
    }
}
