package bingol.campus.post.core.converter;

import bingol.campus.post.core.response.PostDTO;
import bingol.campus.post.entity.Post;
import bingol.campus.student.entity.Student;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;

@Component
@RequiredArgsConstructor
public class PostConverterImpl implements PostConverter {


    @Override
    public PostDTO toDto(Post post) {
        LocalDateTime now = LocalDateTime.now();
        LocalDateTime postTime = post.getCreatedAt();

        if (postTime == null) {
            postTime = now;
        }

        return PostDTO.builder()
                .postId(post.getId())
                .like(post.getLikes().size())
                .comment(post.getComments().size())
                .popularityScore(post.getPopularityScore())
                .profilePhoto(post.getStudent().getProfilePhoto())
                .content(post.getPhotos())
                .createdAt(postTime)
                .howMoneyMinutesAgo(formatTimeAgo(postTime, now))  // ⬅ Zaman hesaplaması için
                .description(post.getDescription())
                .tagAPerson(post.getTaggedPersons().stream().map(Student::getUsername).toList())
                .location(post.getLocation())
                .username(post.getStudent().getUsername())
                .userId(post.getStudent().getId())
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



}
