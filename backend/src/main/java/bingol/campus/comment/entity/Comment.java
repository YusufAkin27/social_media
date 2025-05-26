package bingol.campus.comment.entity;

import bingol.campus.student.entity.Student; // Öğrenci entity'si için import
import bingol.campus.post.entity.Post;     // Gönderi entity'si için import
import bingol.campus.story.entity.Story;   // Hikaye entity'si için import
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@AllArgsConstructor
@NoArgsConstructor
@Builder
@Data
@Entity
public class Comment {

    @Id
    @GeneratedValue(generator = "UUID")
    @Column(updatable = false, nullable = false)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "author_id", nullable = false)
    private Student student; // Yorumu yapan öğrenci

    @ManyToOne
    @JoinColumn(name = "post_id")
    private Post post; // Yorumun ait olduğu gönderi (nullable, çünkü ya post ya da story olacak)

    @ManyToOne
    @JoinColumn(name = "story_id")
    private Story story; // Yorumun ait olduğu hikaye (nullable, çünkü ya post ya da story olacak)

    @Column(nullable = false)
    private String content; // Yorumun içeriği

    private LocalDateTime createdAt = LocalDateTime.now(); // Yorumun oluşturulma tarihi

}
