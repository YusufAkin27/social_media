package bingol.campus.story.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class StoryNotActiveException extends BusinessException {
    public StoryNotActiveException( ) {
        super("Hikaye Aktif değil");
    }
}
