package bingol.campus.story.entity;

import bingol.campus.comment.entity.Comment;
import bingol.campus.student.entity.Student;
import bingol.campus.like.entity.Like;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@AllArgsConstructor
@NoArgsConstructor
@Builder
@Data
@Entity
public class Story {

    @Id
    @GeneratedValue(generator = "UUID")
    @Column(updatable = false, nullable = false)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "author_id", nullable = false)
    private Student student;

    private String photo;

    private LocalDateTime createdAt = LocalDateTime.now();

    private LocalDateTime expiresAt;

    private boolean isFeatured =false;

    private boolean isActive=true;

    private long score;

    @ManyToOne
    @JoinColumn(name = "featured_story_id")
    private FeaturedStory featuredStory; // Eğer hikaye bir "öne çıkarılan hikaye" grubuna bağlıysa

    @OneToMany(cascade = CascadeType.ALL, mappedBy = "story")
    private List<Like> likes = new ArrayList<>(); // Hikayelere yapılan beğeniler

    @OneToMany(cascade = CascadeType.ALL, mappedBy = "story")
    private List<Comment> comments = new ArrayList<>(); // Hikayeye yapılan yorumlar

    @OneToMany(cascade = CascadeType.ALL, mappedBy = "story")
    private List<StoryViewer> viewers = new ArrayList<>(); // Hikayeyi görüntüleyen kullanıcılar


    public boolean getIsActive() {
        return expiresAt == null || expiresAt.isAfter(LocalDateTime.now());
    }

}
