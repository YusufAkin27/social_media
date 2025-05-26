package bingol.campus.security.exception;

public class UserDeletedException extends BusinessException {
    public UserDeletedException() {
        super("Kullanıcı silinmiş.");
    }
}
