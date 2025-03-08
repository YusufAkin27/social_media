package bingol.campus.story.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class FeaturedStoryGroupNotFoundException extends BusinessException {
    public FeaturedStoryGroupNotFoundException( ) {
        super("Öne Çıkarılan grup bulunamadı");
    }
}
