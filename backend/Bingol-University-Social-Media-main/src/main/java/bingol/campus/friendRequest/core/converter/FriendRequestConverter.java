package bingol.campus.friendRequest.core.converter;

import bingol.campus.followRelation.entity.FollowRelation;
import bingol.campus.friendRequest.core.response.FollowedUserDTO;
import bingol.campus.friendRequest.core.response.ReceivedFriendRequestDTO;
import bingol.campus.friendRequest.core.response.SentFriendRequestDTO;
import bingol.campus.friendRequest.entity.FriendRequest;

public interface FriendRequestConverter {
    ReceivedFriendRequestDTO receivedToDto(FriendRequest friendRequest);

    SentFriendRequestDTO sentToDto(FriendRequest friendRequest);

    FollowedUserDTO followingToDto(FollowRelation followRelation);

    FollowedUserDTO followersToDto(FollowRelation followRelation);


}
