package bingol.campus.security.exception;

public class UserNotFoundException extends BusinessException {
    public UserNotFoundException() {
        super("Kullanıcı bulunamadı");
    }
}
