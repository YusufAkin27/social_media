package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class VideoSizeLargerException extends BusinessException {
    public VideoSizeLargerException( ) {
        super("Video boyutu 50MB'den büyük olamaz.");
    }
}
