package bingol.campus.story.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class OwnerStoryException extends BusinessException {
    public OwnerStoryException( ) {
        super("Bu hikaye, öğrenciye ait değil: ");
    }
}
