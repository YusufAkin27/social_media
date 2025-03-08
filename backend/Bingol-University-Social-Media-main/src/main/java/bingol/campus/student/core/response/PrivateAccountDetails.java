package bingol.campus.student.core.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.List;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class PrivateAccountDetails {
    private long id;
    private String username;
    private String profilePhoto;
    private String bio;
    private boolean isFollow;
    private List<String> commonFriends;
    private long followingCount;
    private long followerCount;
    private long postCount;
    private boolean isSentRequest;
    private boolean isPrivate;
    private long popularityScore;

}
