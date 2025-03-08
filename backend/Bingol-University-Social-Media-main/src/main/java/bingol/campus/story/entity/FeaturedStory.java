package bingol.campus.story.entity;

import bingol.campus.student.entity.Student;
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

@Data
@Entity
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class FeaturedStory {

    @Id
    @GeneratedValue(generator = "UUID")
    @Column(updatable = false, nullable = false)
    private UUID id; // Öne çıkarılan hikaye grubu ID'si

    private String coverPhoto;

    private String title; // Öne çıkarılan hikaye grubunun adı (örn: "Tatillerim", "Spor Anılarım" gibi)
    private LocalDateTime createAt;

    @ManyToOne
    @JoinColumn(name = "student_id", nullable = false)
    private Student student; // Bu öne çıkarılan hikaye grubunu oluşturan öğrenci

    @OneToMany(mappedBy = "featuredStory", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<Story> stories = new ArrayList<>(); // Bu gruba ait hikayeler


}
