package bingol.campus.security.exception;

public class InvalidRefreshTokenException extends BusinessException {
    public InvalidRefreshTokenException() {
        super("Geçersiz yenileme tokenı");
    }
}
