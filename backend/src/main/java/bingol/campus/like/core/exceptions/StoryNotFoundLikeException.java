package bingol.campus.like.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class StoryNotFoundLikeException extends BusinessException {
    public StoryNotFoundLikeException( ) {
        super("Hikayeyi beğeniniz bulunamadı");
    }
}
