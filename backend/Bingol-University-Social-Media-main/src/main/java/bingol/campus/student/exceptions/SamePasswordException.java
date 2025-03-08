package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;

public class SamePasswordException extends BusinessException {
    public SamePasswordException() {
        super("Yeni şifre mevcut şifreyle aynı olamaz.");
    }
}
