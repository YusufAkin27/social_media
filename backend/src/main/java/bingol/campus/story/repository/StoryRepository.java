package bingol.campus.story.repository;

import bingol.campus.story.entity.Story;
import bingol.campus.student.entity.Student;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface StoryRepository extends JpaRepository<Story, UUID> {
    Page<Story> findByStudentInAndIsActiveTrueOrderByCreatedAtDesc(List<Student> followingList, Pageable pageable);

    List<Story> findByStudent(Student student1);

    long countByCreatedAt(LocalDateTime today);
    @Query("SELECT s FROM Story s WHERE s.expiresAt <= CURRENT_TIMESTAMP AND s.isActive = true")
    List<Story> findExpiredStories();
    Page<Story> findByStudentAndIsActive(Student student, boolean b, Pageable pageable);
}
