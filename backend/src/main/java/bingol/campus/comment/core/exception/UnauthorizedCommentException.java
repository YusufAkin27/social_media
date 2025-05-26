package bingol.campus.comment.core.exception;

import bingol.campus.security.exception.BusinessException;

public class UnauthorizedCommentException extends BusinessException {
    public UnauthorizedCommentException( ) {
        super("Bu yoruma erişim hakkın yok");
    }
}
