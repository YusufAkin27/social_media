package bingol.campus.followRelation.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class BlockingBetweenStudent extends BusinessException {
    public BlockingBetweenStudent( ) {
        super("Kullanıcılar arasında engelleme mevcut.");
    }
}
