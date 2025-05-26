package bingol.campus.post.business.abstracts;

import bingol.campus.post.core.exceptions.*;

import bingol.campus.post.core.response.CommentDetailsDTO;
import bingol.campus.post.core.response.LikeDetailsDTO;
import bingol.campus.post.core.response.PostDTO;

import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.security.exception.UserNotFoundException;
import bingol.campus.story.core.exceptions.OwnerStoryException;
import bingol.campus.story.core.exceptions.StoryNotFoundException;
import bingol.campus.student.exceptions.*;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.UUID;

public interface PostService {

    ResponseMessage delete(String username, UUID postId) throws PostNotFoundException, StudentNotFoundException, PostAlreadyDeleteException, PostAlreadyNotActiveException, PostNotFoundForUserException, UserNotFoundException;


    DataResponseMessage<PostDTO>getDetails(String username, UUID postId) throws StudentNotFoundException, PostNotFoundException, PostAccessDeniedWithBlockerException, PostAccessDeniedWithPrivateException;




    ResponseMessage getLikeCount(String username, UUID postId) throws StudentNotFoundException, PostNotFoundException, PostAccessDeniedWithBlockerException, PostAccessDeniedWithPrivateException;

    ResponseMessage getCommentCount(String username, UUID postId) throws StudentNotFoundException, PostNotFoundException, PostAccessDeniedWithBlockerException, PostAccessDeniedWithPrivateException;

    ResponseMessage add(String username, String description, String location, List<String> tagAPerson, MultipartFile[] photos) throws InvalidPostRequestException, StudentNotFoundException, UnauthorizedTaggingException, BlockedUserTaggedException, IOException, OnlyPhotosAndVideosException, PhotoSizeLargerException, VideoSizeLargerException, FileFormatCouldNotException;

    ResponseMessage update(String username, UUID postId, String description, String location, List<String> tagAPerson, MultipartFile[] photos) throws StudentNotFoundException, PostNotFoundException, PostNotFoundForUserException, IOException, UnauthorizedTaggingException, BlockedUserTaggedException, OnlyPhotosAndVideosException, PhotoSizeLargerException, VideoSizeLargerException, FileFormatCouldNotException;

    DataResponseMessage<List<PostDTO>> getMyPosts(String username, Pageable pageRequest) throws StudentNotFoundException;

    DataResponseMessage<List<PostDTO>> getUserPosts(String username, String username1, Pageable pageable) throws PostAccessDeniedWithBlockerException, PostAccessDeniedWithPrivateException, StudentNotFoundException;

    DataResponseMessage<List<LikeDetailsDTO>> getLikeDetails(String username, UUID postId, Pageable pageable) throws StudentNotFoundException, PostNotFoundException, PostAccessDeniedWithPrivateException, PostAccessDeniedWithBlockerException;

    DataResponseMessage<List<CommentDetailsDTO>> getCommentDetails(String username, UUID postId, Pageable pageable) throws StudentNotFoundException, PostNotFoundException, PostAccessDeniedWithBlockerException, PostAccessDeniedWithPrivateException;

    DataResponseMessage<List<LikeDetailsDTO>> getStoryLikeDetails(String username, UUID storyId, Pageable pageRequest) throws StudentNotFoundException, OwnerStoryException, StoryNotFoundException, PostAccessDeniedWithPrivateException, PostAccessDeniedWithBlockerException;

    DataResponseMessage<List<CommentDetailsDTO>> getStoryCommentDetails(String username, UUID storyId, Pageable pageRequest) throws StudentNotFoundException, StoryNotFoundException, PostAccessDeniedWithBlockerException, PostAccessDeniedWithPrivateException;

    DataResponseMessage<List<PostDTO>> archivedPosts(String username) throws StudentNotFoundException;

    ResponseMessage deleteArchived(String username, UUID postId) throws StudentNotFoundException, PostNotFoundException, ArchivedNotFoundPost;

    DataResponseMessage<List<PostDTO>> recorded(String username) throws StudentNotFoundException;

    DataResponseMessage<List<PostDTO>> getPopularity(String username) throws StudentNotFoundException;

    boolean isRecorded(String username, UUID postId) throws StudentNotFoundException;

    ResponseMessage deleteRecorded(UserDetails userDetails, UUID postId) throws StudentNotFoundException;

    ResponseMessage addRecorded(UserDetails userDetails, UUID postId) throws StudentNotFoundException;
}
