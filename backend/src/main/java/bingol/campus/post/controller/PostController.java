package bingol.campus.post.controller;

import bingol.campus.post.business.abstracts.PostService;
import bingol.campus.post.core.exceptions.*;

import bingol.campus.post.core.response.CommentDetailsDTO;
import bingol.campus.post.core.response.LikeDetailsDTO;
import bingol.campus.post.core.response.PostDTO;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.security.entity.User;
import bingol.campus.security.exception.UserNotFoundException;
import bingol.campus.story.core.exceptions.OwnerStoryException;
import bingol.campus.story.core.exceptions.StoryNotFoundException;
import bingol.campus.student.exceptions.*;
import lombok.Data;
import lombok.RequiredArgsConstructor;

import org.checkerframework.checker.units.qual.A;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/v1/api/post")
@RequiredArgsConstructor
public class PostController {
    private final PostService postService;


    @PostMapping("/add")
    public ResponseMessage add(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(value = "description", required = false) String description,
            @RequestParam(value = "location", required = false) String location,
            @RequestParam(value = "tagAPerson", required = false) List<String> tagAPerson,
            @RequestParam("mediaFiles") MultipartFile[] mediaFiles)
            throws UnauthorizedTaggingException, InvalidPostRequestException, StudentNotFoundException, BlockedUserTaggedException, IOException, OnlyPhotosAndVideosException, PhotoSizeLargerException, VideoSizeLargerException, FileFormatCouldNotException {
        return postService.add(userDetails.getUsername(), description, location, tagAPerson, mediaFiles);
    }


    @DeleteMapping("/{postId}")
    public ResponseMessage add(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID postId) throws UserNotFoundException, PostNotFoundForUserException, PostNotFoundException, PostAlreadyNotActiveException, StudentNotFoundException, PostAlreadyDeleteException {
        return postService.delete(userDetails.getUsername(), postId);
    }

    @PutMapping("/{postId}")
    public ResponseMessage updatePost(@AuthenticationPrincipal UserDetails userDetails,
                                      @PathVariable UUID postId,
                                      @RequestParam(value = "description", required = false) String description,
                                      @RequestParam(value = "location", required = false) String location,
                                      @RequestParam(value = "tagAPerson", required = false) List<String> tagAPerson,
                                      @RequestParam(value = "photos", required = false) MultipartFile[] photos) throws UnauthorizedTaggingException, InvalidPostRequestException, StudentNotFoundException, BlockedUserTaggedException, IOException, PostNotFoundForUserException, PostNotFoundException, OnlyPhotosAndVideosException, PhotoSizeLargerException, VideoSizeLargerException, FileFormatCouldNotException {
        return postService.update(userDetails.getUsername(), postId, description, location, tagAPerson, photos);
    }

    @GetMapping("/details/{postId}")
    public DataResponseMessage<PostDTO> getPostDetails(@AuthenticationPrincipal UserDetails userDetails,
                                                       @PathVariable UUID postId) throws StudentNotFoundException, PostAccessDeniedWithPrivateException, PostNotFoundException, PostAccessDeniedWithBlockerException {
        return postService.getDetails(userDetails.getUsername(), postId);
    }

    @GetMapping("/my-posts")
    public DataResponseMessage<List<PostDTO>> getMyPosts(@AuthenticationPrincipal UserDetails userDetails, Pageable pageable) throws StudentNotFoundException {
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), 10);
        return postService.getMyPosts(userDetails.getUsername(), pageRequest);
    }


    @GetMapping("/{username}/posts")
    public DataResponseMessage<List<PostDTO>> getUserPosts(@AuthenticationPrincipal UserDetails userDetails,
                                                           @PathVariable String username,
                                                           Pageable pageable) throws PostAccessDeniedWithPrivateException, StudentNotFoundException, PostAccessDeniedWithBlockerException {
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), 10);

        return postService.getUserPosts(userDetails.getUsername(), username, pageRequest);
    }


    @GetMapping("/like-count/{postId}")
    public ResponseMessage getLikeCount(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID postId) throws PostAccessDeniedWithPrivateException, PostNotFoundException, StudentNotFoundException, PostAccessDeniedWithBlockerException {
        return postService.getLikeCount(userDetails.getUsername(), postId);
    }

    @GetMapping("/comment-count/{postId}")
    public ResponseMessage getCommentCount(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID postId) throws PostAccessDeniedWithPrivateException, PostNotFoundException, StudentNotFoundException, PostAccessDeniedWithBlockerException {
        return postService.getCommentCount(userDetails.getUsername(), postId);
    }

    @GetMapping("/like-details/{postId}")
    public DataResponseMessage<List<LikeDetailsDTO>> getLikeDetails(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID postId,
            Pageable pageable) throws PostAccessDeniedWithPrivateException, PostNotFoundException, StudentNotFoundException, PostAccessDeniedWithBlockerException {
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), 10);
        return postService.getLikeDetails(userDetails.getUsername(), postId, pageRequest);
    }

    @GetMapping("/comment-details/{postId}")
    public DataResponseMessage<List<CommentDetailsDTO>> getCommentDetails(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID postId,
            Pageable pageable) throws PostAccessDeniedWithPrivateException, PostNotFoundException, StudentNotFoundException, PostAccessDeniedWithBlockerException {
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), 10);
        return postService.getCommentDetails(userDetails.getUsername(), postId, pageRequest);
    }

    @GetMapping("/like-details/{storyId}")
    public DataResponseMessage<List<LikeDetailsDTO>> getStoryLikeDetails(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID storyId,
            Pageable pageable) throws PostAccessDeniedWithPrivateException, PostNotFoundException, StudentNotFoundException, PostAccessDeniedWithBlockerException, StoryNotFoundException, OwnerStoryException {
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), 10);
        return postService.getStoryLikeDetails(userDetails.getUsername(), storyId, pageRequest);
    }

    @GetMapping("/comment-details/{storyId}")
    public DataResponseMessage<List<CommentDetailsDTO>> getStoryCommentDetails(
            @AuthenticationPrincipal UserDetails userDetails,
            @PathVariable UUID storyId,
            Pageable pageable) throws PostAccessDeniedWithPrivateException, PostNotFoundException, StudentNotFoundException, PostAccessDeniedWithBlockerException, StoryNotFoundException {
        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), 10);
        return postService.getStoryCommentDetails(userDetails.getUsername(), storyId, pageRequest);
    }

    @GetMapping("/archivedPosts")
    public DataResponseMessage<List<PostDTO>> archivedPosts(@AuthenticationPrincipal UserDetails userDetails) throws StudentNotFoundException {
        return postService.archivedPosts(userDetails.getUsername());
    }

    // arşivden kaldırma
    @DeleteMapping("/{postId}/archivedPost")
    public ResponseMessage deleteArchived(@AuthenticationPrincipal UserDetails userDetails
            , @PathVariable UUID postId) throws PostNotFoundException, ArchivedNotFoundPost, StudentNotFoundException {
        return postService.deleteArchived(userDetails.getUsername(), postId);
    }

    // kaydedilenler
    @GetMapping("/recorded")
    public DataResponseMessage<List<PostDTO>> recorded(@AuthenticationPrincipal UserDetails userDetails) throws StudentNotFoundException {
        return postService.recorded(userDetails.getUsername());
    }

    @GetMapping("/recorded/{postId}/check")
    public boolean isRecorded(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID postId) throws StudentNotFoundException {
        return postService.isRecorded(userDetails.getUsername(),postId);
    }
    @PostMapping("/recorded/{postId}")
    public ResponseMessage addRecorded(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID postId) throws  StudentNotFoundException {
        return postService.addRecorded(userDetails,postId);
    }
    @DeleteMapping("/recorded/{postId}")
    public ResponseMessage deleteRecorded(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID postId) throws StudentNotFoundException {
        return postService.deleteRecorded(userDetails,postId);
    }

    @GetMapping("/getPopularity")
    public DataResponseMessage<List<PostDTO>> getPopularity(@AuthenticationPrincipal UserDetails userDetails) throws StudentNotFoundException {
        return postService.getPopularity(userDetails.getUsername());
    }


}
