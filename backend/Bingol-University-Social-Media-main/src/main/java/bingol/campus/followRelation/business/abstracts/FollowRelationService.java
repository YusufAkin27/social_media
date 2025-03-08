package bingol.campus.followRelation.business.abstracts;

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
import org.springframework.data.domain.Pageable;

import java.util.List;

public interface FollowRelationService {

    ResponseMessage deleteFollowing(String username, Long userId) throws StudentNotFoundException, FollowRelationNotFoundException, StudentDeletedException, StudentNotActiveException;

    ResponseMessage deleteFollower(String username, Long userId) throws StudentNotFoundException, FollowRelationNotFoundException, StudentDeletedException, StudentNotActiveException;

    ResponseMessage getFollowersCount(String username) throws StudentNotFoundException;

    ResponseMessage getFollowingCount(String username) throws StudentNotFoundException;

    DataResponseMessage<List<String>> getCommonFollowers(String username, String username1) throws StudentNotFoundException;

    DataResponseMessage<List<PostDTO>> getFollowingPosts(String username, String username1) throws StudentNotFoundException;

    DataResponseMessage<List<SearchAccountDTO>> getUsernameFollowers(String username, String username1) throws StudentNotFoundException, BlockingBetweenStudent, UnauthorizedAccessException;

    DataResponseMessage<List<SearchAccountDTO>> getUsernameFollowing(String username, String username1) throws StudentNotFoundException, BlockingBetweenStudent, UnauthorizedAccessException;

    DataResponseMessage<List<SearchAccountDTO>> searchInFollowers(String username, String username1, String query) throws StudentNotFoundException, BlockingBetweenStudent, UnauthorizedAccessException;

    DataResponseMessage<List<SearchAccountDTO>> searchInFollowing(String username, String username1, String query) throws StudentNotFoundException, BlockingBetweenStudent, UnauthorizedAccessException;

    DataResponseMessage<List<FollowedUserDTO>> getFollowing(String username, Pageable pageable) throws StudentNotFoundException;

    DataResponseMessage<List<FollowedUserDTO>> getFollowers(String username, Pageable pageable) throws StudentNotFoundException;

    DataResponseMessage<List<FollowedUserDTO> > searchFollowers(String username, String query, Pageable pageable) throws StudentNotFoundException;

    DataResponseMessage<List<FollowedUserDTO> > searchFollowing(String username, String query, Pageable pageable) throws StudentNotFoundException;
}
