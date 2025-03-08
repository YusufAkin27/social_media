package bingol.campus.security.entity.enums;

public enum TokenType {
    ACCESS,   // Kullanıcıların hızlı kimlik doğrulaması için kullanılan kısa ömürlü token
    REFRESH  // ACCESS token'ın süresi dolduğunda yenilemek için kullanılan uzun ömürlü token

}
