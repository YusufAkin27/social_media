package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class DuplicateEmailException extends BusinessException {
    public DuplicateEmailException( ) {
        super("Aynı email de başka öğrenci var");
    }
}
