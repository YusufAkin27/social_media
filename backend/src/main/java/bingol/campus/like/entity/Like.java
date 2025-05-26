package bingol.campus.like.entity;

import bingol.campus.student.entity.Student;  // Öğrenci entity'si için import
import bingol.campus.post.entity.Post;  // Gönderi entity'si için import
import bingol.campus.story.entity.Story;  // Hikaye entity'si için import
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
@Table(name = "\"like\"")  // Tablo adı çift tırnak içinde tanımlandı
public class Like {

    @Id
    @GeneratedValue(generator = "UUID")
    @Column(updatable = false, nullable = false)
    private UUID id;  // Beğeni ID'si
    private LocalDateTime createdAt=LocalDateTime.now();
    @ManyToOne
    @JoinColumn(name = "student_id", nullable = false)
    private Student student;  // Beğeniyi yapan öğrenci

    @ManyToOne
    @JoinColumn(name = "post_id", nullable = true)
    private Post post;  // Beğenilen gönderi (null olabilir çünkü hikaye de beğenilebilir)

    @ManyToOne
    @JoinColumn(name = "story_id", nullable = true)
    private Story story;  // Beğenilen hikaye (null olabilir çünkü gönderi de beğenilebilir)

    private LocalDate likedAt = LocalDate.now();  // Beğeninin yapıldığı zaman
}
