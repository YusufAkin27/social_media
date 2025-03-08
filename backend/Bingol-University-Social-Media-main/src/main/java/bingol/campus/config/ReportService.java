package bingol.campus.config;

import bingol.campus.comment.repository.CommentRepository;
import bingol.campus.like.repository.LikeRepository;
import bingol.campus.mailservice.EmailMessage;
import bingol.campus.mailservice.MailService;
import bingol.campus.post.repository.PostRepository;
import bingol.campus.security.entity.Role;
import bingol.campus.story.repository.StoryRepository;
import bingol.campus.student.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.List;

@Service
@RequiredArgsConstructor
@Slf4j
public class ReportService {

    private final StudentRepository userRepository;
    private final PostRepository postRepository;
    private final CommentRepository commentRepository;
    private final MailService mailService;
    private final StoryRepository storyRepository;
    private final LikeRepository likeRepository;

    public void generateDailyReportScheduled() {
        log.info("📢 Günlük rapor oluşturuluyor...");

        String report = generateDailyReport();

        List<String> adminEmails = userRepository.findEmailsByRoles(Role.ADMIN);

        if (adminEmails.isEmpty()) {
            log.warn("⚠ Hiçbir admin e-posta adresi bulunamadı!");
            return;
        }
        log.info("✅ Günlük rapor başarıyla oluşturuldu, {} admin kullanıcısına gönderilecek.", adminEmails.size());
        for (String email:adminEmails) {
            EmailMessage emailMessage = new EmailMessage();
            emailMessage.setSubject("📊 Günlük Rapor");
            emailMessage.setHtml(true);
            emailMessage.setBody(report);
            emailMessage.setToEmail(email);
            mailService.queueEmail(emailMessage);
        }


        log.info("📧 Günlük rapor adminlere başarıyla gönderildi.");
    }


    public String generateDailyReport() {
        try {
            LocalDateTime today = LocalDateTime.now();
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("dd-MM-yyyy");

            // Günlük İstatistikler
            long newUsersToday = userRepository.countByCreatedAt(today);
            long newPostsToday = postRepository.countByCreatedAt(today);
            long newCommentsToday = commentRepository.countByCreatedAt(today);
            long newStoriesToday = storyRepository.countByCreatedAt(today);
            long newLikesToday = likeRepository.countByCreatedAt(today);

            long totalInteractionsToday = newLikesToday + newCommentsToday;

            // Genel İstatistikler
            long totalUsers = userRepository.count();
            long totalPosts = postRepository.count();
            long totalComments = commentRepository.count();
            long totalStories = storyRepository.count();
            long totalLikes = likeRepository.count();
            long totalInteractions = totalLikes + totalComments;

            return """
                <html>
                <head>
                    <style>
                        body { font-family: Arial, sans-serif; background-color: #f4f4f4; padding: 20px; }
                        .container { background: white; padding: 20px; border-radius: 8px; box-shadow: 0 0 10px rgba(0,0,0,0.1); }
                        h2 { color: #2c3e50; }
                        h3 { color: #16a085; margin-top: 20px; }
                        .highlight { font-weight: bold; color: #2980b9; }
                        table { width: 100%%; border-collapse: collapse; margin-top: 10px; }
                        th, td { padding: 10px; text-align: left; border-bottom: 1px solid #ddd; }
                        th { background-color: #3498db; color: white; }
                        tr:hover { background-color: #f1f1f1; }
                        .footer { margin-top: 20px; font-size: 12px; color: #7f8c8d; text-align: center; }
                    </style>
                </head>
                <body>
                    <div class="container">
                        <h2>📊 Günlük Rapor - %s</h2>

                        <h3>📅 Bugünkü İstatistikler</h3>
                        <table>
                            <tr><th>Kategori</th><th>Bugün</th></tr>
                            <tr><td>👥 Yeni Kullanıcı</td><td class="highlight">%d</td></tr>
                            <tr><td>📝 Yeni Gönderiler</td><td class="highlight">%d</td></tr>
                            <tr><td>💬 Yeni Yorumlar</td><td class="highlight">%d</td></tr>
                            <tr><td>📸 Yeni Hikayeler</td><td class="highlight">%d</td></tr>
                            <tr><td>❤️ Yeni Beğeniler</td><td class="highlight">%d</td></tr>
                            <tr><td>⚡ Toplam Etkileşim</td><td class="highlight">%d</td></tr>
                        </table>

                        <h3>📊 Genel İstatistikler</h3>
                        <table>
                            <tr><th>Kategori</th><th>Toplam</th></tr>
                            <tr><td>👥 Toplam Kullanıcı</td><td class="highlight">%d</td></tr>
                            <tr><td>📝 Toplam Gönderi</td><td class="highlight">%d</td></tr>
                            <tr><td>💬 Toplam Yorum</td><td class="highlight">%d</td></tr>
                            <tr><td>📸 Toplam Hikaye</td><td class="highlight">%d</td></tr>
                            <tr><td>❤️ Toplam Beğeni</td><td class="highlight">%d</td></tr>
                            <tr><td>⚡ Toplam Etkileşim</td><td class="highlight">%d</td></tr>
                        </table>

                        <div class="footer">🔹 BinGoo! Rapor Sistemi - %s 🔹</div>
                    </div>
                </body>
                </html>
                """.formatted(
                    today.format(formatter),
                    newUsersToday, newPostsToday, newCommentsToday, newStoriesToday, newLikesToday, totalInteractionsToday,
                    totalUsers, totalPosts, totalComments, totalStories, totalLikes, totalInteractions,
                    today.format(formatter)
            );

        } catch (Exception e) {
            log.error("Günlük rapor oluşturulurken hata oluştu! Hata mesajı: {}", e.getMessage(), e);
            return "<h2 style='color:red;'>⚠ Rapor oluşturulurken hata oluştu.</h2>";
        }
    }

}
