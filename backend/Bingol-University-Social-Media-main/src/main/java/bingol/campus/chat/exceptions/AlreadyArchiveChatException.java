package bingol.campus.chat.exceptions;

import bingol.campus.security.exception.BusinessException;

public class AlreadyArchiveChatException extends BusinessException {
    public AlreadyArchiveChatException() {
        super("Already archived chat");
    }
}
