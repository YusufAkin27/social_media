package bingol.campus.story.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class FeaturedStoryGroupNotAccess extends BusinessException {
    public FeaturedStoryGroupNotAccess( ) {
        super("öne çıkarılan hikayeleri siz düzenleyemezsiniz");
    }
}
