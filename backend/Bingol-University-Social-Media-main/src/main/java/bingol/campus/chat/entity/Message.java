package bingol.campus.chat.entity;

import bingol.campus.student.entity.Student;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Entity
@Table(name = "messages")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class Message {
    @Id
    @GeneratedValue(generator = "UUID")
    @Column(updatable = false, nullable = false)
    private UUID id;

    @ManyToOne
    @JoinColumn(name = "chat_id", nullable = false)
    private Chat chat;

    @ManyToOne
    @JoinColumn(name = "sender_id", nullable = false)
    private Student sender;

    private String content;
    private LocalDateTime createdAt;
    private LocalDateTime updatedAt;
    private Boolean isPinned;
    private Boolean isEdited;
    private Boolean isDeleted;
    private Boolean isActive;

    @ElementCollection
    private List<Long> seenBy = new ArrayList<>();

    @ElementCollection
    private List<String> mediaUrls = new ArrayList<>();
}