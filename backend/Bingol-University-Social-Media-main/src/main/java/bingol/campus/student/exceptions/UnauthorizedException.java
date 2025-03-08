package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class UnauthorizedException extends BusinessException {
    public UnauthorizedException( ) {
        super("Buraya  giriş yetkiniz yok" );
    }
}
