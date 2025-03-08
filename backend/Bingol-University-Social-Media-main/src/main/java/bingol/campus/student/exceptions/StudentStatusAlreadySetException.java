package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class StudentStatusAlreadySetException extends BusinessException {
    public StudentStatusAlreadySetException() {
        super("Öğrencinin durumunda bi değişiklilik olmadı");
    }
}
