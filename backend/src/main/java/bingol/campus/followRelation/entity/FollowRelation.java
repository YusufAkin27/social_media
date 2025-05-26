package bingol.campus.followRelation.entity;

import bingol.campus.student.entity.Student;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
public class FollowRelation {

    @Id
    @GeneratedValue(generator = "UUID")
    @Column(updatable = false, nullable = false)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "follower_id", nullable = false)
    private Student follower; // Takip eden öğrenci

    @ManyToOne
    @JoinColumn(name = "followed_id", nullable = false)
    private Student followed; // Takip edilen öğrenci

    private LocalDate followingDate = LocalDate.now(); // Takip edilme tarihi

}
