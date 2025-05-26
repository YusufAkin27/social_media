package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class StudentNotFoundException extends BusinessException {
    public StudentNotFoundException( ) {
        super("Öğrenci bulunamadı");
    }
}
