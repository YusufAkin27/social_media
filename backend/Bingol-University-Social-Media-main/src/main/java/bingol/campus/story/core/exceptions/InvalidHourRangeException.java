package bingol.campus.story.core.exceptions;

import bingol.campus.security.exception.BusinessException;

public class InvalidHourRangeException extends BusinessException {
    public InvalidHourRangeException( ) {
        super("Süre uzatma yalnızca 1 ile 24 saat arasında olmalıdır.");
    }
}
