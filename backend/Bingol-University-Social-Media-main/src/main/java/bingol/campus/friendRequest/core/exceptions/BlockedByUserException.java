package bingol.campus.friendRequest.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class BlockedByUserException extends BusinessException {
    public BlockedByUserException( ) {
        super("Bu kullanıcıyı engellediğiniz için işlem yapamıyoruz");
    }
}
