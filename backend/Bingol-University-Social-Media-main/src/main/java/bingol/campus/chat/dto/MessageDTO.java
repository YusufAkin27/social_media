package bingol.campus.chat.dto;

import bingol.campus.chat.entity.Chat;
import bingol.campus.student.entity.Student;
import com.fasterxml.jackson.annotation.JsonFormat;
import jakarta.persistence.*;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDateTime;
import java.util.UUID;


@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class MessageDTO {
    private UUID messageId;
    private String content;
    private String senderUsername;
    private long receiverId;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime sentAt;
    private UUID chatId;
    @JsonFormat(shape = JsonFormat.Shape.STRING, pattern = "yyyy-MM-dd HH:mm:ss")
    private LocalDateTime updatedAt;
    private Boolean isPinned;
    private Boolean isDeleted;


}
