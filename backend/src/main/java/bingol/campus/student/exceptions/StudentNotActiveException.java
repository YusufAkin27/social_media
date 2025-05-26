package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class StudentNotActiveException extends BusinessException {
    public StudentNotActiveException( ) {
        super("Öğrenci aktif değil");
    }
}
