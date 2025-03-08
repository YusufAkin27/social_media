package bingol.campus.chat.request;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@AllArgsConstructor
@NoArgsConstructor
public class DeleteMessageRequest {
    private UUID messageId;
    private UUID chatId;
}
