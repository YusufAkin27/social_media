package bingol.campus.story.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class AlreadyFeaturedStoriesException extends BusinessException {
    public AlreadyFeaturedStoriesException() {
        super("Bu hikaye zaten öne çıkarılanlar listesinde");
    }
}
