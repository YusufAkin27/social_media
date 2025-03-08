package bingol.campus.blockRelation.repository;

import bingol.campus.blockRelation.entity.BlockRelation;
import bingol.campus.student.entity.Student;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface BlockRelationRepository extends JpaRepository<BlockRelation, UUID> {
    Page<BlockRelation> findByBlocker(Student student, Pageable pageable);
}
