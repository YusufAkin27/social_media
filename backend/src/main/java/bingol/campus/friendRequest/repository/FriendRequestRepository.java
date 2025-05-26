package bingol.campus.friendRequest.repository;

import bingol.campus.friendRequest.entity.FriendRequest;
import bingol.campus.student.entity.Student;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.Pageable;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface FriendRequestRepository extends JpaRepository<FriendRequest, UUID> {
    void deleteBySenderAndReceiver(Student student, Student student1);

    Page<FriendRequest> findByReceiver(Student student, Pageable pageable);

    Page<FriendRequest> findBySender(Student student, Pageable pageable);
}
