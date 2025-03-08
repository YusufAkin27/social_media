package bingol.campus.chat.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;
@Data
@AllArgsConstructor
@NoArgsConstructor
public class EditMessageRequest {
    private UUID messageId;
    private UUID chatId;
    private String content;

}
