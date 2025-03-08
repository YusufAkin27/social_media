package bingol.campus.verificationToken;

import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import java.time.LocalDateTime;

@Service
public class VerificationTokenCleanupService {
    private final VerificationTokenRepository verificationTokenRepository;

    public VerificationTokenCleanupService(VerificationTokenRepository verificationTokenRepository) {
        this.verificationTokenRepository = verificationTokenRepository;
    }

    // Her gece saat 2'de süresi dolan tokenları temizle
    @Scheduled(cron = "0 0 2 * * ?")
    public void cleanExpiredTokens() {
        verificationTokenRepository.deleteByExpiryDateBefore(LocalDateTime.now());
        System.out.println("Süresi dolmuş tokenlar temizlendi.");
    }
}
