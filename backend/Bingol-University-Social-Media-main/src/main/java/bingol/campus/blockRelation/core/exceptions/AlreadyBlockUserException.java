package bingol.campus.blockRelation.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class AlreadyBlockUserException extends BusinessException {
    public AlreadyBlockUserException( ) {
        super("Kullanıcı zaten engellenmiş");
    }
}
