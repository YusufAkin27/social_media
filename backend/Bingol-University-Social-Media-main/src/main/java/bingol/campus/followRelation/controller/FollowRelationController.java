package bingol.campus.followRelation.controller;

import bingol.campus.followRelation.business.abstracts.FollowRelationService;
import bingol.campus.followRelation.core.exceptions.BlockingBetweenStudent;
import bingol.campus.followRelation.core.exceptions.FollowRelationNotFoundException;
import bingol.campus.followRelation.core.exceptions.UnauthorizedAccessException;
import bingol.campus.friendRequest.core.response.FollowedUserDTO;
import bingol.campus.post.core.response.PostDTO;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.student.core.response.SearchAccountDTO;
import bingol.campus.student.exceptions.StudentDeletedException;
import bingol.campus.student.exceptions.StudentNotActiveException;
import bingol.campus.student.exceptions.StudentNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/api/follow-relations")
@RequiredArgsConstructor
public class FollowRelationController {

    private final FollowRelationService followRelationService;

    // Kullanıcının takip ettiği kişileri sayfalı şekilde al
    @GetMapping("/following")
    public DataResponseMessage<List<FollowedUserDTO>> getFollowing(@AuthenticationPrincipal UserDetails userDetails, Pageable pageable) throws StudentNotFoundException {
        return followRelationService.getFollowing(userDetails.getUsername(), pageable);
    }

    // Kullanıyı takip eden kişileri sayfalı şekilde al
    @GetMapping("/followers")
    public DataResponseMessage<List<FollowedUserDTO>> getFollowers(@AuthenticationPrincipal UserDetails userDetails, Pageable pageable) throws StudentNotFoundException {
        return followRelationService.getFollowers(userDetails.getUsername(), pageable);
    }


    // Takip edilen birini sil
    @DeleteMapping("/following/{userId}")
    public ResponseMessage removeFollowing(@AuthenticationPrincipal UserDetails userDetails, @PathVariable Long userId) throws StudentNotFoundException, FollowRelationNotFoundException, StudentDeletedException, StudentNotActiveException {
        return followRelationService.deleteFollowing(userDetails.getUsername(), userId);
    }

    // Takipçi birini sil
    @DeleteMapping("/followers/{userId}")
    public ResponseMessage removeFollower(@AuthenticationPrincipal UserDetails userDetails, @PathVariable Long userId) throws StudentNotFoundException, FollowRelationNotFoundException, StudentDeletedException, StudentNotActiveException {
        return followRelationService.deleteFollower(userDetails.getUsername(), userId);
    }

    // Takipçi arama (Kullanıcı adı veya isimle) sayfalama ile
    @GetMapping("/followers/search")
    public DataResponseMessage<List<FollowedUserDTO> > searchFollowers(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam String query,
            Pageable pageable) throws StudentNotFoundException {
        return followRelationService.searchFollowers(userDetails.getUsername(), query, pageable);
    }

    // Takip edilen kişiler arasında arama (Kullanıcı adı veya isimle) sayfalama ile
    @GetMapping("/following/search")
    public DataResponseMessage<List<FollowedUserDTO> > searchFollowing(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam String query,
            Pageable pageable) throws StudentNotFoundException {
        return followRelationService.searchFollowing(userDetails.getUsername(), query, pageable);
    }

    // Kullanıcının takipçi sayısını ve takip edilen kişi sayısını göster
    @GetMapping("/followers-count")
    public ResponseMessage getFollowersCount(@AuthenticationPrincipal UserDetails userDetails) throws StudentNotFoundException {
        return followRelationService.getFollowersCount(userDetails.getUsername());
    }

    @GetMapping("/following-count")
    public ResponseMessage getFollowingCount(@AuthenticationPrincipal UserDetails userDetails) throws StudentNotFoundException {
        return followRelationService.getFollowingCount(userDetails.getUsername());
    }


    // Ortak takipçileri göster (Hem takipçi hem takip edilen)
    @GetMapping("/common-followers/{username}")
    public DataResponseMessage<List<String>> getCommonFollowers(@AuthenticationPrincipal UserDetails userDetails, @PathVariable String username) throws StudentNotFoundException {
        return followRelationService.getCommonFollowers(userDetails.getUsername(), username);
    }

    // Takip edilen veya takipçi kişilerin paylaşımlarını göster
    @GetMapping("/following/{username}/posts")
    public DataResponseMessage<List<PostDTO>> getFollowingPosts(@AuthenticationPrincipal UserDetails userDetails, @PathVariable String username) throws StudentNotFoundException {
        return followRelationService.getFollowingPosts(userDetails.getUsername(), username);
    }

    // Herhangi bir kullanıcının takipçi listesi
    @GetMapping("/followers/{username}")
    public DataResponseMessage<List<SearchAccountDTO>> getFollowers(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable String username) throws StudentNotFoundException, BlockingBetweenStudent, UnauthorizedAccessException {
        return followRelationService.getUsernameFollowers(userDetails.getUsername(), username);
    }

    // Herhangi bir kullanıcının takip ettiği kullanıcılar listesi
    @GetMapping("/following/{username}")
    public DataResponseMessage<List<SearchAccountDTO>> getFollowing(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable String username) throws StudentNotFoundException, BlockingBetweenStudent, UnauthorizedAccessException {
        return followRelationService.getUsernameFollowing(userDetails.getUsername(), username);
    }

    // Takipçi listesinde arama yapma
    @GetMapping("/followers/search/{username}")
    public DataResponseMessage<List<SearchAccountDTO>> searchInFollowers(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable String username,
            @RequestParam String query) throws StudentNotFoundException, BlockingBetweenStudent, UnauthorizedAccessException {
        return followRelationService.searchInFollowers(userDetails.getUsername(), username, query);
    }

    // Takip edilenler listesinde arama yapma
    @GetMapping("/following/search/{username}")
    public DataResponseMessage<List<SearchAccountDTO>> searchInFollowing(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable String username,
            @RequestParam String query) throws StudentNotFoundException, BlockingBetweenStudent, UnauthorizedAccessException {
        return followRelationService.searchInFollowing(userDetails.getUsername(), username, query);
    }
}
