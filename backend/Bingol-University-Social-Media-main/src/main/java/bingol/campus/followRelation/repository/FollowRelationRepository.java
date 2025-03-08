package bingol.campus.followRelation.repository;

import bingol.campus.followRelation.entity.FollowRelation;
import bingol.campus.student.entity.Student;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

public interface FollowRelationRepository extends JpaRepository<FollowRelation,Long> {
    void deleteByFollowerAndFollowed(Student student, Student student1);

    Page<FollowRelation> findByFollower(Student student, Pageable pageRequest);

    Page<FollowRelation> findByFollowed(Student student, Pageable pageRequest);

    // Takipçi arama sorgusu (Kullanıcı adı veya isimle)
    @Query("SELECT fr FROM FollowRelation fr WHERE fr.follower = :student AND (fr.follower.username LIKE %:query% OR fr.follower.firstName LIKE %:query% OR fr.follower.lastName LIKE %:query%)")
    Page<FollowRelation> findByFollowerAndStudentContaining(@Param("student") Student student, @Param("query") String query, Pageable pageable);

    // Takip edilen kullanıcılar arama sorgusu (Kullanıcı adı veya isimle)
    @Query("SELECT fr FROM FollowRelation fr WHERE fr.followed = :student AND (fr.followed.username LIKE %:query% OR fr.followed.firstName LIKE %:query% OR fr.followed.lastName LIKE %:query%)")
    Page<FollowRelation> findByFollowedAndStudentContaining(@Param("student") Student student, @Param("query") String query, Pageable pageable);

}
