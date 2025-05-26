package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class InvalidTcIdentityNumberException extends BusinessException {
    public InvalidTcIdentityNumberException() {
        super("TC Kimlik numarası 11 rakamdan oluşmalıdır.");
    }
}
