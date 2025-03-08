package bingol.campus.friendRequest.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class UserBlockedException extends BusinessException {
    public UserBlockedException( ) {
        super("Bu kullanıcı sizi engellemiş ");
    }
}
