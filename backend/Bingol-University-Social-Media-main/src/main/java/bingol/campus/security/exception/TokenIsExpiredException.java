package bingol.campus.security.exception;

public class TokenIsExpiredException extends BusinessException  {

    public TokenIsExpiredException() {
        super("Token  süresi dolmuş");
    }
}
