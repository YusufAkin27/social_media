package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class InvalidOperationException extends BusinessException {
    public InvalidOperationException( ) {
        super(" Öğrenci zaten silinmemiş.");
    }
}
