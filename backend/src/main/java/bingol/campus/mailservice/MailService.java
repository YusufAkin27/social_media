package bingol.campus.mailservice;

import bingol.campus.security.exception.BusinessException;
import bingol.campus.student.exceptions.EmailSendException;
import jakarta.mail.MessagingException;
import jakarta.mail.internet.MimeMessage;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.mail.javamail.JavaMailSender;
import org.springframework.mail.javamail.MimeMessageHelper;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.io.File;
import java.util.ArrayList;
import java.util.List;
import java.util.concurrent.ExecutorService;
import java.util.concurrent.Executors;

@Service
@RequiredArgsConstructor
@Slf4j
public class MailService {

    private final JavaMailSender mailSender;

    @Value("${spring.mail.username}")
    private String senderEmail;

    private final EmailQueue emailQueue = new EmailQueue();
    private final ExecutorService executorService = Executors.newFixedThreadPool(5);

    // E-posta kuyruğuna ekleme
    public void queueEmail(EmailMessage emailMessage) {
        emailQueue.enqueue(emailMessage);
        executorService.submit(() -> processEmail(emailMessage));
    }

    // E-postayı işleyip gönderen metot
    private void processEmail(EmailMessage email) {
        sendEmail(email);
    }

    // E-posta gönderme işlemi
    private void sendEmail(EmailMessage email) {
        MimeMessage mimeMessage = mailSender.createMimeMessage();

        try {
            MimeMessageHelper helper = new MimeMessageHelper(mimeMessage, true, "UTF-8");
            helper.setTo(email.getToEmail());
            helper.setSubject(email.getSubject());
            helper.setText(email.getBody(), email.isHtml());
            helper.setFrom(senderEmail);

            try {
                mailSender.send(mimeMessage);
                log.info("📧 E-posta başarıyla gönderildi: {}", email.getToEmail());
            } catch (Exception e) {
                throw new EmailSendException();
            }

        } catch (MessagingException | EmailSendException e) {
            log.error("E-posta hazırlanırken hata oluştu: {}", e.getMessage());
        }
    }

    // Her 1 dakikada bir kuyruktaki e-postaları gönder
    @Scheduled(fixedRate = 60000)
    public void sendQueuedEmails() {
        int batchSize = Math.max(1, emailQueue.size());
        processBatchEmails(batchSize);
    }

    private void processBatchEmails(int batchSize) {
        List<EmailMessage> emailBatch = new ArrayList<>();

        while (!emailQueue.isEmpty() && emailBatch.size() < batchSize) {
            try {
                emailBatch.add(emailQueue.dequeue());
            } catch (InterruptedException e) {
                Thread.currentThread().interrupt();
                log.error("E-posta gönderim işlemi kesildi: {}", e.getMessage());
            }
        }

        for (EmailMessage email : emailBatch) {
            executorService.submit(() -> sendEmail(email));
        }
    }
}
