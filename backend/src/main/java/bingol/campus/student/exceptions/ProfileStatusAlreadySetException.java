package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class ProfileStatusAlreadySetException extends BusinessException {
    public ProfileStatusAlreadySetException(boolean isPrivate) {
        super("Profil zaten " + (isPrivate ? "kapalı" : "açık") + " durumda.");
    }
}
