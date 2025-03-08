package bingol.campus.security.exception;

public class TokenNotFoundException extends BusinessException {
    public TokenNotFoundException() {
        super("Token bulunamadı.");
    }
}
