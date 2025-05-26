package bingol.campus.post.entity;

import bingol.campus.comment.entity.Comment;
import bingol.campus.student.entity.Student;
import bingol.campus.like.entity.Like;  // Like modelini import ediyoruz
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
public class Post {

    @Id
    @GeneratedValue(generator = "UUID")
    @Column(updatable = false, nullable = false)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "author_id", nullable = false)
    private Student student; // Gönderiyi paylaşan öğrenci

    private List<String> photos;

    @ManyToMany
    @JoinTable(name = "post_tags", joinColumns = @JoinColumn(name = "post_id"), inverseJoinColumns = @JoinColumn(name = "student_id"))
    private List<Student> taggedPersons = new ArrayList<>();

    private long popularityScore;


    private String description;
    private String location; // Örneğin: "New York, USA"
    private boolean isActive;
    private boolean isDelete;


    @Column(name = "created_at")
    private LocalDateTime createdAt; // Gönderinin oluşturulma tarihi

    @OneToMany(cascade = CascadeType.ALL, mappedBy = "post")
    private List<Comment> comments = new ArrayList<>(); // Yorumlar

    // Beğenileri tutacak listeyi 'Like' modeline bağlıyoruz
    @OneToMany(cascade = CascadeType.ALL, mappedBy = "post")
    private List<Like> likes = new ArrayList<>(); // Beğeniler

    @PrePersist
    @PreUpdate
    public void updatePopularityScore() {
        this.popularityScore = calculatePopularityScore();
    }

    // 🎯 Popülerlik skorunu hesaplayan metod
    private long calculatePopularityScore() {
        int likesCount = this.likes != null ? this.likes.size() : 0; // Beğeni sayısı
        int commentsCount = this.comments != null ? this.comments.size() : 0; // Yorum sayısı
        int taggedCount = this.taggedPersons != null ? this.taggedPersons.size() : 0; // Etiketlenen kişi sayısı

        // Popülerlik skoru hesaplama formülü
        return likesCount * 3L + commentsCount * 2L + taggedCount;
    }
}
