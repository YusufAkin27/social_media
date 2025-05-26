package bingol.campus.chat.exceptions;

import bingol.campus.security.exception.BusinessException;

public class MessageNotActiveException extends BusinessException {
    public MessageNotActiveException() {
        super("message is not active");
    }
}
