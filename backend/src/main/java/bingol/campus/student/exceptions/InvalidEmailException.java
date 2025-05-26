package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class InvalidEmailException extends BusinessException {
    public InvalidEmailException( ) {
        super("E-posta formatı geçersiz. 9 haneli numara ve '@bingol.edu.tr' içermelidir.");
    }
}
