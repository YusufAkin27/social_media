package bingol.campus.blockRelation.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class BlockUserNotFoundException extends BusinessException {
    public BlockUserNotFoundException( ) {
        super("Engellenen kullanıcı bulunamadı");
    }
}
