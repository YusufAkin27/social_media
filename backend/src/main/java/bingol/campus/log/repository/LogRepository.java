package bingol.campus.log.repository;

import bingol.campus.log.entity.Log;
import bingol.campus.student.entity.Student;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Modifying;
import org.springframework.data.jpa.repository.Query;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;

public interface LogRepository extends JpaRepository<Log, UUID> {


    // 1 AYDAN ESKİ LOG'LARI SİL
    @Transactional
    @Modifying
    @Query("DELETE FROM Log l WHERE l.sendTime < :time")
    void deleteOldLogs(LocalDateTime time);

    List<Log> findByStudentAndSendTimeAfterAndIsActiveTrue(Student student, LocalDateTime oneMonthAgo);
}
