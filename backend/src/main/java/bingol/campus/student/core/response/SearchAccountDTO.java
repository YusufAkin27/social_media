package bingol.campus.student.core.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class SearchAccountDTO {
    private long id;
    private String fullName;
    private String profilePhoto;
    private String username;
}
