package bingol.campus.chat.exceptions;

import bingol.campus.security.exception.BusinessException;

public class PrivateChatNotFoundException extends BusinessException {
    public PrivateChatNotFoundException( ) {
        super("Private chat not found");
    }
}
