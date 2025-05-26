package bingol.campus.chatbot.entity;

import bingol.campus.student.entity.Student;
import jakarta.persistence.*;
import lombok.*;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.ArrayList;
import java.util.List;

@Entity
@Data
@NoArgsConstructor
@AllArgsConstructor
@Table(name = "courses")
public class Course {

    @Id
    @GeneratedValue(strategy = GenerationType.IDENTITY)
    private Long id;

    private String name; // Dersin adı

    @Enumerated(EnumType.STRING)
    private DayOfWeek day; // Ders günü (PAZARTESİ, SALI vs.)

    private LocalTime startTime; // Başlangıç saati
    private LocalTime endTime;   // Bitiş saati


    @ManyToMany(mappedBy = "courses", fetch = FetchType.LAZY)
    private List<Student> students = new ArrayList<>();
}
