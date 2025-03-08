package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class FileFormatCouldNotException extends BusinessException {
    public FileFormatCouldNotException( ) {
        super("Dosya formatı belirlenemedi.");
    }
}
