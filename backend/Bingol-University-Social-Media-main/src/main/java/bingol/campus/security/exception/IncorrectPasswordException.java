package bingol.campus.security.exception;
public class IncorrectPasswordException extends BusinessException {
    public IncorrectPasswordException() {
        super("Hatalı şifre");
    }
}
