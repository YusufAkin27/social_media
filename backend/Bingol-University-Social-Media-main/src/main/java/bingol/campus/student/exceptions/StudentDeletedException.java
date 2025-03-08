package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class StudentDeletedException extends BusinessException {
    public StudentDeletedException( ) {
        super("Öğrenci Hesabını silmiş");
    }
}
