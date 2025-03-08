package bingol.campus.chat.dto;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;


@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class PrivateChatDTO {
    private UUID chatId;

    private String chatName;
    private String chatPhoto;

    private String username1;

    private String username2;

    private MessageDTO lastEndMessage;
}
