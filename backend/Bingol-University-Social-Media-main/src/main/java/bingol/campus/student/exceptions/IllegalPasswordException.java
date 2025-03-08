package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class IllegalPasswordException extends BusinessException {
    public IllegalPasswordException( ) {
        super("Şifre en az 6 karakter uzunluğunda olmalıdır.");
    }
}
