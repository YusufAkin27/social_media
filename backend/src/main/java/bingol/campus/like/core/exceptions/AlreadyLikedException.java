package bingol.campus.like.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class AlreadyLikedException extends BusinessException {
    public AlreadyLikedException( ) {
        super("Zaten beğenmişsiniz");
    }
}
