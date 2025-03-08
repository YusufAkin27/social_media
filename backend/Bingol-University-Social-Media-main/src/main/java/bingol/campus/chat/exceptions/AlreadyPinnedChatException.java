package bingol.campus.chat.exceptions;

import bingol.campus.security.exception.BusinessException;

public class AlreadyPinnedChatException extends BusinessException {
    public AlreadyPinnedChatException() {
        super("Already pinned chat");
    }
}
