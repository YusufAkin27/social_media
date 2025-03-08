package bingol.campus.chat.exceptions;

import bingol.campus.security.exception.BusinessException;

public class PrivateChatParticipantNotFoundException extends BusinessException {
    public PrivateChatParticipantNotFoundException() {
        super("Private chat participant not found");
    }
}
