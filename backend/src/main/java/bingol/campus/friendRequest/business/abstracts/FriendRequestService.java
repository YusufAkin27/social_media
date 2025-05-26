package bingol.campus.friendRequest.business.abstracts;

import bingol.campus.friendRequest.core.exceptions.*;

import bingol.campus.friendRequest.core.response.ReceivedFriendRequestDTO;
import bingol.campus.friendRequest.core.response.SentFriendRequestDTO;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.student.exceptions.StudentDeletedException;
import bingol.campus.student.exceptions.StudentNotActiveException;
import bingol.campus.student.exceptions.StudentNotFoundException;
import org.springframework.data.domain.Pageable;

import java.util.List;
import java.util.UUID;

public interface FriendRequestService {
    ResponseMessage sendFriendRequest(String username, String  username2) throws StudentNotFoundException, SelfFriendRequestException, AlreadySentRequestException, AlreadyFollowingException, BlockedByUserException, UserBlockedException, StudentDeletedException, StudentNotActiveException;
    ResponseMessage acceptFriendRequest(String username, UUID requestId) throws AlreadyAcceptedRequestException, FriendRequestNotFoundException, StudentNotFoundException, UnauthorizedRequestException, StudentDeletedException, StudentNotActiveException;

    ResponseMessage rejectFriendRequest(String username, UUID requestId) throws AlreadyRejectedRequestException, FriendRequestNotFoundException, StudentNotFoundException, StudentDeletedException, StudentNotActiveException;

    DataResponseMessage<?> getFriendRequestById(String username, UUID requestId) throws UnauthorizedRequestException, FriendRequestNotFoundException, StudentNotFoundException;

    ResponseMessage cancelFriendRequest(String username, UUID requestId) throws FriendRequestNotFoundException, UnauthorizedRequestException, StudentNotFoundException;



    ResponseMessage acceptFriendRequestsBulk(String username, List<UUID> requestIds) throws StudentNotFoundException;

    ResponseMessage rejectFriendRequestsBulk(String username, List<UUID> requestIds) throws StudentNotFoundException;

    DataResponseMessage<List<ReceivedFriendRequestDTO>> getReceivedFriendRequests(String username, Pageable pageable) throws StudentNotFoundException;

    DataResponseMessage<List<SentFriendRequestDTO>> getSentFriendRequests(String username, Pageable pageable) throws StudentNotFoundException;
}
