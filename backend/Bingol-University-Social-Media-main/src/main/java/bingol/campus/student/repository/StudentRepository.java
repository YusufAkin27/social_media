
package bingol.campus.student.repository;

import bingol.campus.security.entity.Role;
import bingol.campus.student.entity.Student;
import bingol.campus.student.entity.enums.Department;
import bingol.campus.student.entity.enums.Faculty;
import bingol.campus.student.entity.enums.Grade;
import bingol.campus.student.exceptions.StudentNotFoundException;
import org.springframework.data.domain.Page;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import org.springframework.transaction.annotation.Transactional;

import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.Optional;
import java.util.Set;
import java.util.UUID;

public interface StudentRepository extends JpaRepository<Student, Long> {

    default Student getByUserNumber(String username) throws StudentNotFoundException {
        return findByUserNumber(username)
                .orElseThrow(StudentNotFoundException::new);
    }

    Optional<Student> findByUserNumber(String username);

    boolean existsByMobilePhone(String mobilePhone);

    boolean existsByEmail(String email);

    boolean existsByUserNumber(String schoolNumber);


    // Öğrencinin aktiflik durumunu güncelleyen sorgu
    @Modifying
    @Transactional
    @Query("UPDATE Student s SET s.isActive = :isActive WHERE s.id = :studentId")
    int updateStudentStatus(@Param("studentId") Long studentId, @Param("isActive") Boolean isActive);

    @Query(value = "SELECT s FROM Student s WHERE " +
            "(LOWER(s.firstName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(s.lastName) LIKE LOWER(CONCAT('%', :query, '%')) OR " +
            "LOWER(s.username) LIKE LOWER(CONCAT('%', :query, '%'))) " +
            "AND (COALESCE(:excludedUserIds, NULL) IS NULL OR s.id NOT IN :excludedUserIds)")
    List<Student> searchStudents(
            @Param("query") String query,
            @Param("excludedUserIds") Set<Long> excludedUserIds,
            Pageable pageable);


    @Query("SELECT s FROM Student s WHERE s.department = :department")
    Page<Student> findStudentsByDepartment(@Param("department") Department department, Pageable pageable);
    @Query("SELECT s FROM Student s WHERE s.faculty = :faculty")
    Page<Student> findStudentsByFaculty(@Param("faculty") Faculty faculty, Pageable pageable);
    @Query("SELECT s FROM Student s WHERE s.grade = :grade")
    Page<Student> findStudentsByGrade(@Param("grade") Grade grade, Pageable pageable);

    @Query("SELECT s FROM Student s WHERE LOWER(s.username) = LOWER(:identifier) OR LOWER(s.email) = LOWER(:identifier)")
    Optional<Student> findByUsernameOrEmail(@Param("identifier") String identifier);

    default Student getByUsernameOrEmail(String identifier) throws StudentNotFoundException {
        return findByUsernameOrEmail(identifier)
                .orElseThrow(StudentNotFoundException::new);
    }


    Optional<Student> findByEmail(String email);

    long countByCreatedAt(LocalDateTime today);

    @Query("SELECT s.email FROM Student s WHERE :role MEMBER OF s.roles")
    List<String> findEmailsByRoles(@Param("role") Role role);

    List<Student> findByRoles(Role role);


    @Query("SELECT br.blocked.id FROM BlockRelation br WHERE br.blocker.id = :studentId " +
            "UNION " +
            "SELECT br.blocker.id FROM BlockRelation br WHERE br.blocked.id = :studentId")
    Set<Long> getBlockedUserIds(@Param("studentId") Long studentId);

    @Query("SELECT COUNT(br) > 0 FROM BlockRelation br WHERE br.blocker.id = :blockerId AND br.blocked.id = :blockedId")
    boolean isBlockedBy(@Param("blockerId") Long blockerId, @Param("blockedId") Long blockedId);

}