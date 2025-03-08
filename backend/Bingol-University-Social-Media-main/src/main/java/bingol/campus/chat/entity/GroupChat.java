package bingol.campus.chat.entity;

import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
@Entity
@Table(name = "group_chats")
@Data
@NoArgsConstructor
@AllArgsConstructor
public class GroupChat extends Chat {
    @OneToMany(mappedBy = "chat", cascade = CascadeType.ALL, fetch = FetchType.LAZY)
    private List<ChatParticipant> participants = new ArrayList<>();
}