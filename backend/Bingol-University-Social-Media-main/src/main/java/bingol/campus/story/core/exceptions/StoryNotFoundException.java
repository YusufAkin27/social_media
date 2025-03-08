package bingol.campus.story.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class StoryNotFoundException extends BusinessException {
    public StoryNotFoundException( ) {
        super("Hikaye bulunamadı");
    }
}
