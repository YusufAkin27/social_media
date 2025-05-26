package bingol.campus.post.repository;

import bingol.campus.post.entity.Post;
import bingol.campus.student.entity.Student;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface PostRepository extends JpaRepository<Post, UUID>{

    Page<Post> findByStudentInAndIsActiveTrueAndIsDeleteFalse(List<Student> followingList, Pageable pageable);

    List<Post> findByStudent(Student student1);

    Page<Post> findByStudentAndIsActive(Student student, boolean b, Pageable pageable);

    long countByCreatedAt(LocalDateTime today);
}
