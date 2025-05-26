package bingol.campus.followRelation.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class UnauthorizedAccessException extends BusinessException {
    public UnauthorizedAccessException( ) {
        super("Bu hesabın takipçilerini görüntüleme yetkiniz yok.");
    }
}
