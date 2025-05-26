package bingol.campus.story.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class StudentProfilePrivateException extends BusinessException {
    public StudentProfilePrivateException( ) {
        super("Kullanıcının profili gizli bakamazsınız");
    }
}
