package bingol.campus.comment.controller;

import bingol.campus.comment.business.abstracts.CommentService;

import bingol.campus.comment.core.exception.CommentNotFoundException;
import bingol.campus.comment.core.exception.UnauthorizedCommentException;
import bingol.campus.comment.core.response.CommentDTO;
import bingol.campus.followRelation.core.exceptions.BlockingBetweenStudent;
import bingol.campus.post.core.exceptions.PostNotFoundException;
import bingol.campus.post.core.exceptions.PostNotIsActiveException;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;

import bingol.campus.story.core.exceptions.NotFollowingException;
import bingol.campus.story.core.exceptions.StoryNotActiveException;
import bingol.campus.story.core.exceptions.StoryNotFoundException;
import bingol.campus.story.core.exceptions.StudentProfilePrivateException;
import bingol.campus.student.exceptions.StudentNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/v1/api/comments") // RESTful standardına uygun çoğul kullanım
@RequiredArgsConstructor
public class CommentController {
    private final CommentService commentService;

    // Hikayeye yorum yapma
    @PostMapping("/story/{storyId}")
    public ResponseMessage addCommentToStory(@AuthenticationPrincipal UserDetails userDetails,
                                             @PathVariable UUID storyId,
                                             @RequestParam String content) throws NotFollowingException, StoryNotActiveException, BlockingBetweenStudent, StoryNotFoundException, StudentNotFoundException, StudentProfilePrivateException {
        return commentService.addCommentToStory(userDetails.getUsername(), storyId, content);
    }

    // Gönderiye yorum yapma
    @PostMapping("/post/{postId}")
    public ResponseMessage addCommentToPost(@AuthenticationPrincipal UserDetails userDetails,
                                            @PathVariable UUID postId,
                                            @RequestParam String content) throws PostNotIsActiveException, NotFollowingException, BlockingBetweenStudent, PostNotFoundException, StudentNotFoundException, StudentProfilePrivateException {
        return commentService.addCommentToPost(userDetails.getUsername(), postId, content);
    }

    // Yorum silme
    @DeleteMapping("/{commentId}")
    public ResponseMessage deleteComment(@AuthenticationPrincipal UserDetails userDetails,
                                         @PathVariable UUID commentId) throws UnauthorizedCommentException, StudentNotFoundException, CommentNotFoundException {
        return commentService.deleteComment(userDetails.getUsername(), commentId);
    }

    // Kullanıcının yaptığı yorumları sayfalı olarak listeleme
    @GetMapping("/user")
    public DataResponseMessage<List<CommentDTO>> getUserComments(@AuthenticationPrincipal UserDetails userDetails, Pageable pageable) throws StudentNotFoundException {
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), 10);
        return commentService.getUserComments(userDetails.getUsername(), pageRequest);
    }



    // Belirli bir hikayedeki yorumları sayfalı olarak listeleme
    @GetMapping("/story/{storyId}")
    public DataResponseMessage<List<CommentDTO>> getStoryComments(@AuthenticationPrincipal UserDetails userDetails,
                                                                  @PathVariable UUID storyId, Pageable pageable) throws NotFollowingException, BlockingBetweenStudent, StoryNotActiveException, StoryNotFoundException, StudentNotFoundException, StudentProfilePrivateException {
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), 10);
        return commentService.getStoryComments(userDetails.getUsername(), storyId, pageRequest);
    }

    // Belirli bir gönderideki yorumları sayfalı olarak listeleme
    @GetMapping("/post/{postId}")
    public DataResponseMessage<List<CommentDTO>> getPostComments(@AuthenticationPrincipal UserDetails userDetails,
                                                                 @PathVariable UUID postId, Pageable pageable) throws PostNotIsActiveException, NotFollowingException, BlockingBetweenStudent, PostNotFoundException, StudentNotFoundException, StudentProfilePrivateException {
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), 10);
        return commentService.getPostComments(userDetails.getUsername(), postId, pageRequest);
    }


    // Belirli bir yorumun detaylarını getirme
    @GetMapping("/{commentId}")
    public DataResponseMessage<CommentDTO> getCommentDetails(@AuthenticationPrincipal UserDetails userDetails,
                                                         @PathVariable UUID commentId) throws UnauthorizedCommentException, StudentNotFoundException, CommentNotFoundException {
        return commentService.getCommentDetails(userDetails.getUsername(), commentId);
    }

    //belli bi hikayede kullanıcı yorumu arama
    @GetMapping("/story/{storyId}/search/{username}")
    public DataResponseMessage<List<CommentDTO>> searchUserInStoryComments(@AuthenticationPrincipal UserDetails userDetails,
                                                                           @PathVariable UUID storyId,
                                                                           @PathVariable String username) throws UnauthorizedCommentException, StoryNotFoundException, StudentNotFoundException {
        return commentService.searchUserInStoryComments(userDetails.getUsername(), storyId, username);
    }
    //belli bi gönderide kullanıcı yorumu arama
    @GetMapping("/post/{postId}/search/{username}")
    public DataResponseMessage<List<CommentDTO>> searchUserInPostComments(@AuthenticationPrincipal UserDetails userDetails,
                                                                    @PathVariable UUID postId,
                                                                    @PathVariable String username) throws PostNotIsActiveException, NotFollowingException, UnauthorizedCommentException, BlockingBetweenStudent, PostNotFoundException, StudentNotFoundException {
        return commentService.searchUserInPostComments(userDetails.getUsername(), postId, username);
    }


}
