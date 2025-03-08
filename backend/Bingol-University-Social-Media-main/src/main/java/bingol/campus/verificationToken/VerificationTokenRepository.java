package bingol.campus.verificationToken;

import bingol.campus.student.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDateTime;
import java.util.Optional;

public interface VerificationTokenRepository extends JpaRepository<VerificationToken, Long> {
    Optional<VerificationToken> findByToken(String token);

    void deleteByExpiryDateBefore(LocalDateTime now);

    Optional<VerificationToken> findByStudentAndType(Student student, VerificationTokenType verificationTokenType);
}
