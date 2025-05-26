package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class InvalidUsernameException extends BusinessException {
    public InvalidUsernameException( ) {
        super("Geçersiz kullanıcı adı: Kullanıcı adı 7 karakterden uzun olmalı ve sadece alfanümerik karakterler, nokta, alt çizgi veya tire içerebilir.");
    }
}
