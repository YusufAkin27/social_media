package bingol.campus.chat.exceptions;

import bingol.campus.security.exception.BusinessException;

public class MessageDoesNotBelongException extends BusinessException {
    public MessageDoesNotBelongException() {
        super("Message does not belong to the chat");
    }
}
