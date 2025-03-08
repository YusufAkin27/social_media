package bingol.campus.log.core.request;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@Builder
@NoArgsConstructor
public class CreateLogRequest {
    private String message;
    private Long studentId;// --> kime gidicek log onun id si
}
