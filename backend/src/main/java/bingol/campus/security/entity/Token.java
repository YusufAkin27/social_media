package bingol.campus.security.entity;

import bingol.campus.security.entity.User;
import bingol.campus.security.entity.enums.TokenType;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;

@Table(
        name = "token",
        uniqueConstraints = @UniqueConstraint(columnNames = {"user_id", "tokenType"})
)
@Entity
@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class Token {
    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String tokenValue;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "user_id", nullable = false)
    private User user;

    private boolean isValid = true;

    private LocalDateTime issuedAt;
    private LocalDateTime expiresAt;
    private LocalDateTime lastUsedAt;

    private String ipAddress;
    private String deviceInfo;

    @Enumerated(EnumType.STRING)
    @Column(nullable = false)
    private TokenType tokenType;
}
