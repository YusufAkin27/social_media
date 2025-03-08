package bingol.campus.security.exception;

public class RefreshTokenExpiredException extends BusinessException{
    public RefreshTokenExpiredException() {
        super("Yenileme Token süresi dolmuş");
    }
}
