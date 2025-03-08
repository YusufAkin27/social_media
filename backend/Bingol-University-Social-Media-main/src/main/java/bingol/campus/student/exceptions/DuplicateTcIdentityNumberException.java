package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class DuplicateTcIdentityNumberException extends BusinessException {
    public DuplicateTcIdentityNumberException( ) {
        super("Aynı TC kimlik numarasında başka öğrenci var");
    }
}
