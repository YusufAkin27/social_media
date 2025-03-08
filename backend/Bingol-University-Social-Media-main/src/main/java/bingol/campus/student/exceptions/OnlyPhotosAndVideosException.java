package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class OnlyPhotosAndVideosException extends BusinessException {
    public OnlyPhotosAndVideosException( ) {
        super("Sadece fotoğraf ve video yüklenebilir.");
    }
}
