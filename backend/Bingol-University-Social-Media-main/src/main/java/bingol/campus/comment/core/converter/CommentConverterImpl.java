package bingol.campus.comment.core.converter;

import bingol.campus.comment.core.response.CommentDTO;
import bingol.campus.comment.entity.Comment;
import bingol.campus.post.core.response.CommentDetailsDTO;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Component
public class CommentConverterImpl implements CommentConverter {
    @Override
    public CommentDTO toDto(Comment comment) {
        return CommentDTO.builder()
                .content(comment.getContent())
                .createdAt(comment.getCreatedAt())
                .postId(comment.getPost().getId())
                .username(comment.getStudent().getUsername())
                .howMoneyMinutesAgo(formatTimeAgo(comment.getCreatedAt(), LocalDateTime.now()))
                .build();
    }
    private String formatTimeAgo(LocalDateTime postTime, LocalDateTime now) {
        if (postTime == null) {
            return "Bilinmeyen zaman";
        }

        Duration duration = Duration.between(postTime, now);

        if (duration.toMinutes() < 60) {
            return duration.toMinutes() + " dakika önce";
        } else if (duration.toHours() < 24) {
            return duration.toHours() + " saat önce";
        } else if (duration.toDays() < 7) {
            return duration.toDays() + " gün önce";
        } else if (duration.toDays() < 30) {
            return (duration.toDays() / 7) + " hafta önce";
        } else {
            DateTimeFormatter formatter = DateTimeFormatter.ofPattern("d MMMM yyyy");
            return postTime.format(formatter) + " tarihinde yüklendi";
        }
    }
    @Override
    public CommentDetailsDTO toDetails(Comment comment) {
        return CommentDetailsDTO.builder()
                .content(comment.getContent())
                .createdAt(comment.getCreatedAt())
                .howMoneyMinutesAgo(formatTimeAgo(comment.getCreatedAt(), LocalDateTime.now()))
                .userId(comment.getStudent().getId())
                .username(comment.getStudent().getUsername())
                .build();

    }
}
