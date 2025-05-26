package bingol.campus.chat.exceptions;

import bingol.campus.security.exception.BusinessException;

public class MessageNotFoundException extends BusinessException {
    public MessageNotFoundException() {
        super("Message not found");
    }
}
