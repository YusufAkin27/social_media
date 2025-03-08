package bingol.campus.security.repository;


import bingol.campus.security.entity.Token;
import bingol.campus.security.entity.enums.TokenType;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;

public interface TokenRepository extends JpaRepository<Token, Long> {


    // Kullanıcı ID'ye göre bir token bulma
    Optional<Token> findTokenByUserId(Long userId);

    // Kullanıcı ID'ye göre tüm tokenları listeleme
    List<Token> findAllByUserId(Long userId);

    Optional<Token> findByTokenValue(String token);



    void deleteAllByUserIdAndTokenType(Long id, TokenType tokenType);

    Optional<Token> findTokenByUserIdAndTokenType(Long id, TokenType tokenType);

    void deleteAllByUserId(Long id);
}
