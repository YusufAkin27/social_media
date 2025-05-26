package bingol.campus.post.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class BlockedUserTaggedException extends BusinessException {
    public BlockedUserTaggedException(String taggedUsername ) {
        super(taggedUsername + " kullanıcısını tagleyemezsiniz. (Engelli)");
    }
}
