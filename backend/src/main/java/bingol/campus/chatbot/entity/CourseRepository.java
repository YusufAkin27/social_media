// CourseRepository'ye eklenmesi gereken metodlar
package bingol.campus.chatbot.entity;

import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;
import java.time.DayOfWeek;
import java.util.List;

public interface CourseRepository extends JpaRepository<Course, Long> {

    /**
     * Belirli bir öğrencinin belirli bir gündeki derslerini getirir
     */
    @Query("SELECT c FROM Course c JOIN c.students s WHERE s.id = :studentId AND c.day = :day")
    List<Course> findByStudentsIdAndDay(@Param("studentId") Long studentId, @Param("day") DayOfWeek day);

    /**
     * Belirli bir öğrencinin tüm derslerini getirir
     */
    @Query("SELECT c FROM Course c JOIN c.students s WHERE s.id = :studentId ORDER BY c.day, c.startTime")
    List<Course> findByStudentsId(@Param("studentId") Long studentId);

    /**
     * Belirli bir öğrencinin belirli gün aralığındaki derslerini getirir
     */
    @Query("SELECT c FROM Course c JOIN c.students s WHERE s.id = :studentId AND c.day IN :days ORDER BY c.day, c.startTime")
    List<Course> findByStudentsIdAndDayIn(@Param("studentId") Long studentId, @Param("days") List<DayOfWeek> days);

    /**
     * Belirli bir öğrencinin belirli saat aralığındaki derslerini getirir (çakışma kontrolü için)
     */
    @Query("SELECT c FROM Course c JOIN c.students s WHERE s.id = :studentId AND c.day = :day " +
            "AND ((c.startTime <= :endTime AND c.endTime >= :startTime))")
    List<Course> findConflictingCourses(@Param("studentId") Long studentId,
                                        @Param("day") DayOfWeek day,
                                        @Param("startTime") java.time.LocalTime startTime,
                                        @Param("endTime") java.time.LocalTime endTime);
}