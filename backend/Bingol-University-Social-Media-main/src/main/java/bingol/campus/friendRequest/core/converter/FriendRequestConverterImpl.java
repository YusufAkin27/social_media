package bingol.campus.friendRequest.core.converter;

import bingol.campus.followRelation.entity.FollowRelation;
import bingol.campus.friendRequest.core.response.FollowedUserDTO;
import bingol.campus.friendRequest.core.response.ReceivedFriendRequestDTO;
import bingol.campus.friendRequest.core.response.SentFriendRequestDTO;
import bingol.campus.friendRequest.entity.FriendRequest;
import org.springframework.stereotype.Component;

@Component
public class FriendRequestConverterImpl implements FriendRequestConverter {

    @Override
    public ReceivedFriendRequestDTO receivedToDto(FriendRequest friendRequest) {
        return ReceivedFriendRequestDTO.builder()
                .requestId(friendRequest.getId()) // Arkadaşlık isteği ID'si
                .senderPhotoUrl(friendRequest.getSender().getProfilePhoto()) // Gönderenin profil fotoğrafı
                .senderUsername(friendRequest.getSender().getUsername()) // Gönderenin kullanıcı adı
                .senderFullName(friendRequest.getSender().getFirstName() + " " + friendRequest.getSender().getLastName()) // Gönderenin tam adı
                .sentAt(friendRequest.getSentAt().toString()) // Gönderilme tarihi/saat (String formatında)
                .popularityScore(friendRequest.getSender().getPopularityScore())
                .build();
    }

    @Override
    public SentFriendRequestDTO sentToDto(FriendRequest friendRequest) {
        return SentFriendRequestDTO.builder()
                .requestId(friendRequest.getId()) // Arkadaşlık isteği ID'si
                .receiverPhotoUrl(friendRequest.getReceiver().getProfilePhoto()) // Alıcının profil fotoğrafı
                .receiverUsername(friendRequest.getReceiver().getUsername()) // Alıcının kullanıcı adı
                .receiverFullName(friendRequest.getReceiver().getFirstName() + " " + friendRequest.getReceiver().getLastName()) // Alıcının tam adı
                .sentAt(friendRequest.getSentAt().toString()) // Gönderilme tarihi/saat (String formatında)
                .status(friendRequest.getStatus().name()) // İstek durumu (örn: PENDING, ACCEPTED, REJECTED)
                .popularityScore(friendRequest.getReceiver().getPopularityScore())
                .build();
    }

    @Override
    public FollowedUserDTO followingToDto(FollowRelation followRelation) {
        FollowedUserDTO followedUserDTO = new FollowedUserDTO();
        followedUserDTO.setId(followRelation.getFollowed().getId());
        followedUserDTO.setFollowedDate(followRelation.getFollowingDate());
        followedUserDTO.setBio(followRelation.getFollowed().getBio());
        followedUserDTO.setPrivate(followRelation.getFollowed().isPrivate());
        followedUserDTO.setActive(followRelation.getFollowed().getIsActive());
        followedUserDTO.setUsername(followRelation.getFollowed().getUsername());
        followedUserDTO.setFullName(followRelation.getFollowed().getFirstName() + " " + followRelation.getFollowed().getLastName());
        followedUserDTO.setPopularityScore(followRelation.getFollowed().getPopularityScore());
        followedUserDTO.setProfilePhotoUrl(followRelation.getFollowed().getProfilePhoto());
        return followedUserDTO;
    }

    @Override
    public FollowedUserDTO followersToDto(FollowRelation followRelation) {
        FollowedUserDTO followedUserDTO = new FollowedUserDTO();
        followedUserDTO.setId(followRelation.getFollower().getId());
        followedUserDTO.setFollowedDate(followRelation.getFollowingDate());
        followedUserDTO.setBio(followRelation.getFollower().getBio());
        followedUserDTO.setPrivate(followRelation.getFollower().isPrivate());
        followedUserDTO.setActive(followRelation.getFollower().getIsActive());
        followedUserDTO.setUsername(followRelation.getFollower().getUsername());
        followedUserDTO.setFullName(followRelation.getFollower().getFirstName() + " " + followRelation.getFollower().getLastName());
        followedUserDTO.setPopularityScore(followRelation.getFollower().getPopularityScore());
        followedUserDTO.setProfilePhotoUrl(followRelation.getFollower().getProfilePhoto());
        return followedUserDTO;
    }


}
