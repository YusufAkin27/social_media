package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class InvalidFacultyException extends BusinessException {
    public InvalidFacultyException( ) {
        super("Geçerli fakülte giriniz");
    }
}
