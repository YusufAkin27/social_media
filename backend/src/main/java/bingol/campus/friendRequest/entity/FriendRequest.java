package bingol.campus.friendRequest.entity;

import bingol.campus.friendRequest.entity.enums.RequestStatus;
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
@AllArgsConstructor
@NoArgsConstructor
@Builder
@Data
public class FriendRequest {
    @Id
    @GeneratedValue(generator = "UUID")
    @Column(updatable = false, nullable = false)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "sender_id", nullable = false)
    private Student sender;
    @ManyToOne
    @JoinColumn(name = "receiver_id", nullable = false)
    private Student receiver;

    @Enumerated(EnumType.STRING)
    private RequestStatus status = RequestStatus.PENDING; // İstek durumu (PENDING, ACCEPTED, REJECTED)

    private LocalDate sentAt = LocalDate.now(); // İsteğin gönderildiği zaman
}
