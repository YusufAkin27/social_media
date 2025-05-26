package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class InvalidMobilePhoneException extends BusinessException {
    public InvalidMobilePhoneException() {
        super("Geçersiz telefon numarası formatı.");
    }
}
