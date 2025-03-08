package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class StudentInactiveException extends BusinessException {
    public StudentInactiveException( ) {
        super("Öğrenci aktif değil");
    }
}
