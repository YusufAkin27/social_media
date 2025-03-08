package bingol.campus.comment.business.abstracts;

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
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.UUID;

public interface CommentService {
    ResponseMessage addCommentToStory(String username, UUID storyId, String content) throws StudentNotFoundException, StoryNotFoundException, StoryNotActiveException, BlockingBetweenStudent, NotFollowingException, StudentProfilePrivateException;

    ResponseMessage addCommentToPost(String username, UUID postId, String content) throws PostNotFoundException, StudentNotFoundException, PostNotIsActiveException, NotFollowingException, BlockingBetweenStudent, StudentProfilePrivateException;

    ResponseMessage deleteComment(String username, UUID commentId) throws CommentNotFoundException, StudentNotFoundException, UnauthorizedCommentException;

    DataResponseMessage<CommentDTO> getCommentDetails(String username, UUID commentId) throws UnauthorizedCommentException, CommentNotFoundException, StudentNotFoundException;


    DataResponseMessage<List<CommentDTO>> searchUserInStoryComments(String username, UUID storyId, String username1) throws UnauthorizedCommentException, StudentNotFoundException, StoryNotFoundException;

    DataResponseMessage<List<CommentDTO>> searchUserInPostComments(String username, UUID postId, String username1) throws PostNotIsActiveException, NotFollowingException, BlockingBetweenStudent, UnauthorizedCommentException, StudentNotFoundException, PostNotFoundException;

    DataResponseMessage<List<CommentDTO>> getUserComments(String username, Pageable pageRequest) throws StudentNotFoundException;

    DataResponseMessage<List<CommentDTO>> getStoryComments(String username, UUID storyId, Pageable pageable) throws NotFollowingException, BlockingBetweenStudent, StoryNotActiveException, StudentNotFoundException, StoryNotFoundException, StudentProfilePrivateException;

    DataResponseMessage<List<CommentDTO>> getPostComments(String username, UUID postId, Pageable pageable) throws StudentNotFoundException, PostNotFoundException, PostNotIsActiveException, NotFollowingException, BlockingBetweenStudent, StudentProfilePrivateException;
}
