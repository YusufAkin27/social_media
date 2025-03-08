package bingol.campus.like.business.abstracts;

import bingol.campus.followRelation.core.exceptions.BlockingBetweenStudent;
import bingol.campus.like.core.exceptions.AlreadyLikedException;
import bingol.campus.like.core.exceptions.PostNotFoundLikeException;
import bingol.campus.like.core.exceptions.StoryNotFoundLikeException;
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

import java.util.List;
import java.util.UUID;

public interface LikeService {
    ResponseMessage likeStory(String username, UUID storyId) throws StoryNotFoundException, StudentNotFoundException, StoryNotActiveException, BlockingBetweenStudent, NotFollowingException, AlreadyLikedException, StudentProfilePrivateException;

    ResponseMessage likePost(String username, UUID postId) throws StudentNotFoundException, PostNotFoundException, PostNotIsActiveException, BlockingBetweenStudent, NotFollowingException, AlreadyLikedException, StudentProfilePrivateException;

    ResponseMessage unlikeStory(String username, UUID storyId) throws StoryNotFoundException, StudentNotFoundException, StoryNotFoundLikeException;

    ResponseMessage unlikePost(String username, UUID postId) throws StudentNotFoundException, PostNotFoundException, PostNotFoundLikeException;

    DataResponseMessage<List<StoryDTO>> getUserLikedStories(String username) throws StudentNotFoundException;

    DataResponseMessage<List<PostDTO>> getUserLikedPosts(String username) throws StudentNotFoundException;

    DataResponseMessage<List<PostDTO>> getPostLikesAfter(UUID postId, String dateTime) throws PostNotFoundException;


    DataResponseMessage<SearchAccountDTO> searchUserInPostLikes(String username, UUID postId, String username1) throws PostNotFoundException, StudentNotFoundException, NotFollowingException, BlockingBetweenStudent, StudentProfilePrivateException;

    DataResponseMessage<SearchAccountDTO> searchUserInStoryLikes(String username, UUID storyId, String username1) throws StudentNotFoundException, StoryNotFoundException, NotFollowingException, BlockingBetweenStudent, StudentProfilePrivateException;

    boolean checkPostLike(String username, UUID postId) throws StudentNotFoundException;

    ResponseMessage togglePostLike(String username, UUID postId) throws StudentNotFoundException, PostNotFoundException;
}
