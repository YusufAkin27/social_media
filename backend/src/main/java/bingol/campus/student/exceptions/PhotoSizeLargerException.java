package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class PhotoSizeLargerException extends BusinessException {
    public PhotoSizeLargerException( ) {
        super("Fotoğraf boyutu 5MB'den büyük olamaz.");
    }
}
