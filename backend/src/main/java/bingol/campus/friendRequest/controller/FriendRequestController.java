package bingol.campus.friendRequest.controller;


import bingol.campus.friendRequest.business.abstracts.FriendRequestService;
import bingol.campus.friendRequest.core.exceptions.*;

import bingol.campus.friendRequest.core.response.ReceivedFriendRequestDTO;
import bingol.campus.friendRequest.core.response.SentFriendRequestDTO;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.student.exceptions.StudentDeletedException;
import bingol.campus.student.exceptions.StudentNotActiveException;
import bingol.campus.student.exceptions.StudentNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Pageable;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;


@RestController
@RequestMapping("/v1/api/friendsRequest")
@RequiredArgsConstructor
public class FriendRequestController {

    private final FriendRequestService friendRequestService;

    // Yeni bir arkadaşlık isteği gönder
    @PostMapping("/send/{username}")
    public ResponseMessage sendFriendRequest(@AuthenticationPrincipal UserDetails userDetails,@PathVariable String username) throws SelfFriendRequestException, StudentNotFoundException, AlreadySentRequestException, AlreadyFollowingException, UserBlockedException, BlockedByUserException, StudentDeletedException, StudentNotActiveException {
        return friendRequestService.sendFriendRequest(userDetails.getUsername(),username);
    }

    // Kullanıcıya gelen arkadaşlık isteklerini getir
    @GetMapping("/received")
    public DataResponseMessage<List<ReceivedFriendRequestDTO>> getReceivedFriendRequests(@AuthenticationPrincipal UserDetails userDetails, Pageable pageable) throws StudentNotFoundException {
        return friendRequestService.getReceivedFriendRequests(userDetails.getUsername(), pageable);
    }

    // Kullanıcı tarafından gönderilen arkadaşlık isteklerini getir
    @GetMapping("/sent")
    public DataResponseMessage<List<SentFriendRequestDTO>> getSentFriendRequests(@AuthenticationPrincipal UserDetails userDetails, Pageable pageable) throws StudentNotFoundException {
        return friendRequestService.getSentFriendRequests(userDetails.getUsername(), pageable);
    }


    // Arkadaşlık isteğini kabul et
    @PutMapping("/accept/{requestId}")
    public ResponseMessage acceptFriendRequest(@AuthenticationPrincipal UserDetails userDetails,@PathVariable UUID requestId) throws AlreadyAcceptedRequestException, FriendRequestNotFoundException, StudentNotFoundException, UnauthorizedRequestException, StudentDeletedException, StudentNotActiveException {
      return   friendRequestService.acceptFriendRequest(userDetails.getUsername(),requestId);
    }

    // Arkadaşlık isteğini reddet
    @PutMapping("/reject/{requestId}")
    public ResponseMessage rejectFriendRequest(@AuthenticationPrincipal UserDetails userDetails,@PathVariable UUID requestId) throws FriendRequestNotFoundException, AlreadyRejectedRequestException, StudentNotFoundException, StudentDeletedException, StudentNotActiveException {
     return    friendRequestService.rejectFriendRequest(userDetails.getUsername(),requestId);

    }

    // Arkadaşlık isteğini iptal et (gönderen tarafından)
    @DeleteMapping("/cancel/{requestId}")
    public ResponseMessage cancelFriendRequest(@AuthenticationPrincipal UserDetails userDetails,@PathVariable UUID requestId) throws UnauthorizedRequestException, FriendRequestNotFoundException, StudentNotFoundException {
        return    friendRequestService.cancelFriendRequest(userDetails.getUsername(),requestId);
    }

    // Belirli bir arkadaşlık isteğini getir
    @GetMapping("/{requestId}")
    public DataResponseMessage<?> getFriendRequestById(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID requestId) throws UnauthorizedRequestException, FriendRequestNotFoundException, StudentNotFoundException {
        return friendRequestService.getFriendRequestById(userDetails.getUsername(), requestId);
    }

    @PutMapping("/reject-bulk")
    public ResponseMessage rejectFriendRequestsBulk(@AuthenticationPrincipal UserDetails userDetails, @RequestBody List<UUID> requestIds) throws StudentNotFoundException, FriendRequestNotFoundException, AlreadyRejectedRequestException {
        return friendRequestService.rejectFriendRequestsBulk(userDetails.getUsername(), requestIds);
    }

    @PutMapping("/accept-bulk")
    public ResponseMessage acceptFriendRequestsBulk(@AuthenticationPrincipal UserDetails userDetails, @RequestBody List<UUID> requestIds) throws StudentNotFoundException, FriendRequestNotFoundException, AlreadyAcceptedRequestException, UnauthorizedRequestException {
        return friendRequestService.acceptFriendRequestsBulk(userDetails.getUsername(), requestIds);
    }


}
