package bingol.campus.chat.exceptions;

import bingol.campus.security.exception.BusinessException;

public class MessageDeletedException extends BusinessException {
    public MessageDeletedException() {
        super("Message is deleted");
    }
}
