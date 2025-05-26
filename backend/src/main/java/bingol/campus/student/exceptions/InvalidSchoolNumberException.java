package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class InvalidSchoolNumberException extends BusinessException
{

    public InvalidSchoolNumberException() {
        super("Öğrenci numarası 9 rakamdan oluşmalıdır.");
    }
}
