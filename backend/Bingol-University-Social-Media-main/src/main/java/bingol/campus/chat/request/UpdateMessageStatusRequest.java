package bingol.campus.chat.request;

import java.util.UUID;
import lombok.Data;

@Data
public class UpdateMessageStatusRequest {
    private UUID messageId;
    private String status; // "delivered" veya "seen"
}
