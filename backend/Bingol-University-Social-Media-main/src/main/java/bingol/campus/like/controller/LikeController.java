package bingol.campus.like.controller;

import bingol.campus.followRelation.core.exceptions.BlockingBetweenStudent;
import bingol.campus.like.business.abstracts.LikeService;
import bingol.campus.like.core.exceptions.AlreadyLikedException;
import bingol.campus.like.core.exceptions.PostNotFoundLikeException;
import bingol.campus.like.core.exceptions.StoryNotFoundLikeException;
import bingol.campus.post.core.exceptions.PostAccessDeniedWithBlockerException;
import bingol.campus.post.core.exceptions.PostAccessDeniedWithPrivateException;
import bingol.campus.post.core.exceptions.PostNotFoundException;
import bingol.campus.post.core.exceptions.PostNotIsActiveException;
import bingol.campus.post.core.response.PostDTO;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.story.core.exceptions.NotFollowingException;
import bingol.campus.story.core.exceptions.StoryNotActiveException;
import bingol.campus.story.core.exceptions.StoryNotFoundException;
import bingol.campus.story.core.exceptions.StudentProfilePrivateException;
import bingol.campus.story.core.response.StoryDTO;
import bingol.campus.student.core.response.SearchAccountDTO;
import bingol.campus.student.exceptions.StudentNotFoundException;
import lombok.Data;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/v1/api/likes") // "like" yerine çoğul "likes" kullanıldı (RESTful best practice)
@RequiredArgsConstructor
public class LikeController {
    private final LikeService likeService;

    // Hikayeyi beğenme
    @PostMapping("/story/{storyId}")
    public ResponseMessage likeStory(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID storyId) throws NotFollowingException, StoryNotActiveException, BlockingBetweenStudent, StoryNotFoundException, StudentNotFoundException, AlreadyLikedException, StudentProfilePrivateException {
        return likeService.likeStory(userDetails.getUsername(), storyId);
    }

    // Gönderiyi beğenme
    @PostMapping("/post/{postId}")
    public ResponseMessage likePost(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID postId) throws PostNotIsActiveException, NotFollowingException, BlockingBetweenStudent, PostNotFoundException, StudentNotFoundException, AlreadyLikedException, StudentProfilePrivateException, PostAccessDeniedWithPrivateException, PostAccessDeniedWithBlockerException {
        return likeService.likePost(userDetails.getUsername(), postId);
    }

    // Hikaye beğenisini kaldırma (Unlike)
    @DeleteMapping("/story/{storyId}")
    public ResponseMessage unlikeStory(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID storyId) throws StoryNotFoundLikeException, StoryNotFoundException, StudentNotFoundException {
        return likeService.unlikeStory(userDetails.getUsername(), storyId);
    }

    // Gönderi beğenisini kaldırma (Unlike)
    @DeleteMapping("/post/{postId}")
    public ResponseMessage unlikePost(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID postId) throws PostNotFoundException, StudentNotFoundException, PostNotFoundLikeException {
        return likeService.unlikePost(userDetails.getUsername(), postId);
    }
    //  beğendiği hikayeleri listele
    @GetMapping("/stories")
    public DataResponseMessage<List<StoryDTO>> getUserLikedStories(@AuthenticationPrincipal UserDetails userDetails) throws StudentNotFoundException {
        return likeService.getUserLikedStories(userDetails.getUsername());
    }
    //  beğendiği gönderileri listele
    @GetMapping("/posts")
    public DataResponseMessage<List<PostDTO>> getUserLikedPosts(@AuthenticationPrincipal UserDetails userDetails) throws StudentNotFoundException {
        return likeService.getUserLikedPosts(userDetails.getUsername());
    }

    // Belirli bir tarihten sonra gönderiye yapılan beğenileri getir
    @GetMapping("/post/{postId}/likes-after/{dateTime}")
    public DataResponseMessage<List<PostDTO>> getPostLikesAfter(@PathVariable UUID postId, @PathVariable String dateTime) throws PostNotFoundException {
        return likeService.getPostLikesAfter(postId, dateTime);
    }
    // Belirtilen hikayede belirli bir kullanıcının beğenisini arama
    @GetMapping("/story/{storyId}/search/{username}")
    public DataResponseMessage<SearchAccountDTO> searchUserInStoryLikes(@AuthenticationPrincipal UserDetails userDetails,@PathVariable UUID storyId, @PathVariable String username) throws NotFollowingException, StoryNotFoundException, StudentNotFoundException, BlockingBetweenStudent, StudentProfilePrivateException {
        return likeService.searchUserInStoryLikes(userDetails.getUsername(),storyId, username);
    }

    // Belirtilen gönderide belirli bir kullanıcının beğenisini arama
    @GetMapping("/post/{postId}/search/{username}")
    public DataResponseMessage<SearchAccountDTO> searchUserInPostLikes(@AuthenticationPrincipal UserDetails userDetails,@PathVariable UUID postId, @PathVariable String username) throws NotFollowingException, PostNotFoundException, StudentNotFoundException, BlockingBetweenStudent, StudentProfilePrivateException {
        return likeService.searchUserInPostLikes(userDetails.getUsername(),postId, username);
    }


    @GetMapping("/post/{postId}/check")
    public boolean checkPostLike(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID postId) throws PostNotFoundException, StudentNotFoundException {
        return likeService.checkPostLike(userDetails.getUsername(), postId);
    }

    @PostMapping("/post/{postId}/toggle")
    public ResponseMessage togglePostLike(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID postId) throws PostNotIsActiveException, NotFollowingException, BlockingBetweenStudent, PostNotFoundException, StudentNotFoundException, AlreadyLikedException, StudentProfilePrivateException, PostAccessDeniedWithPrivateException, PostAccessDeniedWithBlockerException {
        return likeService.togglePostLike(userDetails.getUsername(), postId);
    }

}
