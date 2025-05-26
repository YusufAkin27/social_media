package bingol.campus.log.core.exception;

import bingol.campus.security.exception.BusinessException;

public class LogNotFoundException extends BusinessException {
    public LogNotFoundException( ) {
        super("Log bulunamadı");
    }
}
