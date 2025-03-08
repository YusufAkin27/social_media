package bingol.campus.security.exception;

public class UserNotActiveException extends BusinessException {
    public UserNotActiveException() {
        super("Kullanıcı aktif değil.");
    }
}
