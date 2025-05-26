package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class StudentAlreadyIsActiveException extends BusinessException {
    public StudentAlreadyIsActiveException( ) {
        super("Öğrenci zaten pasif durumda. Silinemez.");
    }
}
