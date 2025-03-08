package bingol.campus.security.service;

import bingol.campus.security.entity.Token;
import bingol.campus.security.entity.User;
import bingol.campus.security.entity.enums.TokenType;
import bingol.campus.security.exception.TokenIsExpiredException;
import bingol.campus.security.exception.TokenNotFoundException;
import bingol.campus.security.repository.TokenRepository;
import bingol.campus.student.entity.Student;
import io.jsonwebtoken.*;
import io.jsonwebtoken.io.Decoders;
import io.jsonwebtoken.security.Keys;
import lombok.NonNull;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;

import javax.crypto.SecretKey;
import java.time.LocalDateTime;
import java.util.Date;
import java.util.Optional;

@Service
public class JwtService {

    private final String accessSecret = "fdkjlsjfkldsjfkldafhliehdjkshgajkjkfincvxkjuvzimfjnvxivoinerji432jkisdfvcxio4";
    private final String refreshSecret = "fajsdfkljslnzufhugeqyewqwiopeoiqueyuyzIOyz786e786wrtwfgyiyzyuiyzuiunewrwrsxg";

    @Value("${jwt.expiration.access}")
    private Long accessExpirationTimeInMs = 15 * 60 * 1000L; // 15 dakika

    @Value("${jwt.expiration.refresh}")
    private Long refreshExpirationTimeInMs = 365 * 24 * 60 * 60 * 1000L; // 1 yıl

    @Autowired
    private TokenRepository tokenRepository;

    public String generateAccessToken(User user, String ipAddress, String deviceInfo) {
        String accessToken = generateToken(user, accessSecret, accessExpirationTimeInMs, true);
        saveToken(user, accessToken, accessExpirationTimeInMs, TokenType.ACCESS, ipAddress, deviceInfo);
        return accessToken;
    }

    public String generateRefreshToken(User user, String ipAddress, String deviceInfo) {
        String refreshToken = generateToken(user, refreshSecret, refreshExpirationTimeInMs, false);
        saveToken(user, refreshToken, refreshExpirationTimeInMs, TokenType.REFRESH, ipAddress, deviceInfo);
        return refreshToken;
    }


    private String generateToken(User user, String secret, Long expirationTimeInMs, boolean includeClaims) {
        JwtBuilder jwtBuilder = Jwts.builder()
                .subject(user.getUsername())
                .signWith(getSignSecretKey(secret))
                .setIssuedAt(new Date())
                .setExpiration(new Date(System.currentTimeMillis() + expirationTimeInMs));

        if (includeClaims) {
            jwtBuilder.claim("userNumber", user.getUserNumber())
                    .claim("role", user.getRoles());
        }

        return jwtBuilder.compact();
    }

    private SecretKey getSignSecretKey(String secret) {
        byte[] keyBytes = Decoders.BASE64.decode(secret);
        return Keys.hmacShaKeyFor(keyBytes);
    }


    private void saveToken(User user, String tokenValue, Long expirationTimeInMs, TokenType tokenType, String ipAddress, String deviceInfo) {
        Optional<Token> existingToken = tokenRepository.findTokenByUserIdAndTokenType(user.getId(), tokenType);

        // Eğer varsa, mevcut token'ı sil
        existingToken.ifPresent(token -> {
            tokenRepository.delete(token);
        });

        // Yeni token kaydı oluştur
        Token token = new Token();
        token.setTokenValue(tokenValue);
        token.setUser(user);
        token.setTokenType(tokenType);
        token.setIssuedAt(LocalDateTime.now());
        token.setExpiresAt(LocalDateTime.now().plusSeconds(expirationTimeInMs / 1000)); // Milisaniyeyi saniyeye çevir
        token.setIpAddress(ipAddress);
        token.setDeviceInfo(deviceInfo);
        token.setValid(true);

        tokenRepository.save(token);

    }


    private boolean validateToken(String token, String secret) throws TokenIsExpiredException, TokenNotFoundException {
        try {
            Claims claims = Jwts.parser()
                    .setSigningKey(getSignSecretKey(secret))
                    .build()
                    .parseClaimsJws(token)
                    .getBody();

            Optional<Token> tokenEntity = tokenRepository.findByTokenValue(token);

            if (tokenEntity.isEmpty() || !tokenEntity.get().isValid()) {
                throw new TokenNotFoundException();
            }

            if (tokenEntity.get().getExpiresAt().isBefore(LocalDateTime.now())) {
                throw new TokenIsExpiredException();
            }

            return true;
        } catch (ExpiredJwtException e) {
            throw new TokenIsExpiredException();
        } catch (JwtException e) {
            throw new TokenNotFoundException();
        }
    }

    public boolean validateRefreshToken(String token) throws TokenIsExpiredException, TokenNotFoundException {
        return validateToken(token, refreshSecret);
    }

    public boolean validateAccessToken(String token) throws TokenIsExpiredException, TokenNotFoundException {
        return validateToken(token, accessSecret);
    }

    public Claims getAccessTokenClaims(String token) {
        return getClaims(token, accessSecret);
    }

    public Claims getRefreshTokenClaims(String token) {
        return getClaims(token, refreshSecret);
    }

    public String extractUsernameFromToken(String token) {
        Claims claims = getClaims(token, accessSecret);
        return claims.getSubject();
    }

    public Claims getClaims(@NonNull String token, @NonNull String secretKey) {
        return Jwts.parser()
                .setSigningKey(getSignSecretKey(secretKey))
                .build()
                .parseClaimsJws(token)
                .getBody();
    }


    public String extractUsername(String token) {
        Optional<Token> optionalToken = tokenRepository.findByTokenValue(token);
        Token token1;
        if (optionalToken.isEmpty()) {
            return null;
        }
        token1 = optionalToken.get();
        return token1.getUser().getUsername();
    }


}
