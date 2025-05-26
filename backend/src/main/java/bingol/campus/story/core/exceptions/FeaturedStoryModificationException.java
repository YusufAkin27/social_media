package bingol.campus.story.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class FeaturedStoryModificationException extends BusinessException {
    public FeaturedStoryModificationException( ) {
        super("Öne çıkarılan hikayelerin süresi uzatılamaz.");
    }
}
