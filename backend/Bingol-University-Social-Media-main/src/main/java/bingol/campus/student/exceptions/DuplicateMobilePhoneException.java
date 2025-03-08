package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class DuplicateMobilePhoneException extends BusinessException {
    public DuplicateMobilePhoneException( ) {
        super("Aynı telefon numarasıyla başka kullanıcı var");
    }
}
