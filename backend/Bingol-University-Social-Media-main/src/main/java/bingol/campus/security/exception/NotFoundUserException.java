package bingol.campus.security.exception;

public class NotFoundUserException extends BusinessException {
    public NotFoundUserException() {
        super("kullanıcı bulunamadı");
    }
}
