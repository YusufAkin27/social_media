package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class DuplicateUsernameException extends BusinessException {
    public DuplicateUsernameException( ) {
        super("Bu kullanıcı adı zaten alınmış.");
    }
}
