package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class EmailSendException extends BusinessException {
    public EmailSendException( ) {
        super("Email gönderilemedi");
    }
}
