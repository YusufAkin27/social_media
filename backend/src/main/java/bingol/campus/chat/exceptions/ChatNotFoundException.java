package bingol.campus.chat.exceptions;

import bingol.campus.security.exception.BusinessException;

public class ChatNotFoundException extends BusinessException {
    public ChatNotFoundException() {
        super("Chat not found");
    }
}
