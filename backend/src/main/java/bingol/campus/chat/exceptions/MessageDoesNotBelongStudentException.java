package bingol.campus.chat.exceptions;

import bingol.campus.security.exception.BusinessException;

public class MessageDoesNotBelongStudentException extends BusinessException {
    public MessageDoesNotBelongStudentException() {
        super("Message does not belong to the student");
    }
}
