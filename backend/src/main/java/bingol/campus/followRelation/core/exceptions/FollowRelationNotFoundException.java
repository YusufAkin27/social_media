package bingol.campus.followRelation.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class FollowRelationNotFoundException extends BusinessException {
    public FollowRelationNotFoundException() {
        super("Takip edilen kullanıcı bulunamadı.");
    }
}
