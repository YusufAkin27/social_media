package bingol.campus.security.exception;

public class UserRoleNotAssignedException extends BusinessException {
    public UserRoleNotAssignedException() {
        super("Kullanıcıya herhangi bir rol atanmamış.");
    }
}
