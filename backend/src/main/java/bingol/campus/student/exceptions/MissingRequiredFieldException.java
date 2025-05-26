package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class MissingRequiredFieldException extends BusinessException {
    public MissingRequiredFieldException( ) {
        super("Ad alanı boş bırakılamaz.");
    }
}
