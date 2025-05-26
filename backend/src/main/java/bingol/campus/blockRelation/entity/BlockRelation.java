package bingol.campus.blockRelation.entity;

import bingol.campus.student.entity.Student;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.UUID;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Builder
@Table(name = "block_relations")
public class BlockRelation {

    @Id
    @GeneratedValue(generator = "UUID")
    @Column(updatable = false, nullable = false)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "blocker_id", nullable = false)
    private Student blocker; // Engelleyen öğrenci

    @ManyToOne
    @JoinColumn(name = "blocked_id", nullable = false)
    private Student blocked; // Engellenen öğrenci

    private LocalDate blockDate = LocalDate.now(); // Engellemeyi gerçekleştiren tarih

}
