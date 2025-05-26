package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class InvalidDepartmentException extends BusinessException {
    public InvalidDepartmentException( ) {
        super("geçerli departman giriniz");
    }
}
