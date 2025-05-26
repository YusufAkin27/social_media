package bingol.campus.post.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class ArchivedNotFoundPost extends BusinessException {
    public ArchivedNotFoundPost() {
        super("arşivde gönderi bulunamadı");
    }
}
