package bingol.campus.friendRequest.business.concretes;

import bingol.campus.followRelation.entity.FollowRelation;
import bingol.campus.followRelation.repository.FollowRelationRepository;
import bingol.campus.friendRequest.business.abstracts.FriendRequestService;
import bingol.campus.friendRequest.core.converter.FriendRequestConverter;
import bingol.campus.friendRequest.core.exceptions.*;
import bingol.campus.friendRequest.entity.FriendRequest;
import bingol.campus.friendRequest.entity.enums.RequestStatus;

import bingol.campus.friendRequest.repository.FriendRequestRepository;
import bingol.campus.friendRequest.core.response.ReceivedFriendRequestDTO;
import bingol.campus.friendRequest.core.response.SentFriendRequestDTO;
import bingol.campus.log.business.abstracts.LogService;
import bingol.campus.log.core.request.CreateLogRequest;
import bingol.campus.notification.NotificationController;
import bingol.campus.notification.SendNotificationRequest;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.student.entity.Student;
import bingol.campus.student.exceptions.StudentDeletedException;
import bingol.campus.student.exceptions.StudentNotActiveException;
import bingol.campus.student.exceptions.StudentNotFoundException;
import bingol.campus.student.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.data.domain.Pageable;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class FriendRequestManager implements FriendRequestService {
    private final StudentRepository studentRepository;
    private final FriendRequestRepository friendRequestRepository;
    private final FollowRelationRepository followRelationRepository;
    private final FriendRequestConverter friendRequestConverter;
    private final NotificationController notificationController;
    private final LogService logService;

    @Override
    @Transactional
    public ResponseMessage sendFriendRequest(String username, String username2) throws StudentNotFoundException, SelfFriendRequestException, AlreadySentRequestException, AlreadyFollowingException, BlockedByUserException, UserBlockedException, StudentDeletedException, StudentNotActiveException {
        Student sent = studentRepository.getByUserNumber(username);
        Student receiver = studentRepository.getByUserNumber(username2);

        if (sent.getId().equals(receiver.getId())) {
            throw new SelfFriendRequestException();
        }

        boolean isFollowing = sent.getFollowing().stream()
                .anyMatch(followRelation -> followRelation.getFollowed().getId().equals(receiver.getId()));

        if (isFollowing) {
            throw new AlreadyFollowingException();
        }

        boolean isBlockedBySender = sent.getBlocked().stream()
                .anyMatch(blockedUser -> blockedUser.getId().equals(receiver.getId()));

        if (isBlockedBySender) {
            throw new BlockedByUserException();
        }

        boolean isBlockedByReceiver = receiver.getBlocked().stream()
                .anyMatch(blockedUser -> blockedUser.getId().equals(sent.getId()));

        if (isBlockedByReceiver) {
            throw new UserBlockedException();
        }

        boolean alreadyRequested = sent.getSentRequest().stream()
                .anyMatch(friendRequest -> friendRequest.getReceiver().getId().equals(receiver.getId()));

        if (alreadyRequested) {
            throw new AlreadySentRequestException();
        }
        if (receiver.isPrivate()) {
            FriendRequest friendRequest = new FriendRequest();
            friendRequest.setReceiver(receiver);
            friendRequest.setSender(sent);
            friendRequest.setSentAt(LocalDate.now());
            friendRequest.setStatus(RequestStatus.PENDING);

            receiver.getReceiverRequest().add(friendRequest);
            sent.getSentRequest().add(friendRequest);
            friendRequestRepository.save(friendRequest);
            CreateLogRequest createLogRequest=new CreateLogRequest();
            createLogRequest.setMessage(sent.getUsername()+" den istek geldi");
            createLogRequest.setStudentId(receiver.getId());
            logService.addLog(createLogRequest);


            if (receiver.getFcmToken() != null) {
                SendNotificationRequest sendNotificationRequest = new SendNotificationRequest();
                sendNotificationRequest.setTitle("İstek Geldi!!");
                sendNotificationRequest.setFmcToken(receiver.getFcmToken());
                sendNotificationRequest.setMessage(sent.getUsername() + " Kullanıcısından istek geldi");

                try {
                    notificationController.sendToUser(sendNotificationRequest);
                } catch (Exception e) {
                    System.err.println("Bildirim gönderme hatası: " + e.getMessage());
                }
            } else {
                System.out.println("Kullanıcının FCM Token değeri bulunamadı!");
            }

            return new ResponseMessage("Arkadaşlık isteği başarıyla gönderildi.", true);

        } else {
            FollowRelation followRelation = new FollowRelation();
            followRelation.setFollower(sent);
            followRelation.setFollowed(receiver);
            followRelation.setFollowingDate(LocalDate.now());

            receiver.getFollowers().add(followRelation);
            sent.getFollowing().add(followRelation);
            followRelationRepository.save(followRelation);

            studentRepository.save(receiver);
            studentRepository.save(sent);
        }

        return new ResponseMessage("Arkadaşlık Eklendi", true);
    }


    public Student findById(Long userId) throws StudentNotFoundException {
        Optional<Student> student = studentRepository.findById(userId);
        if (student.isEmpty()) {
            throw new StudentNotFoundException();
        }
        return student.get();
    }


    @Override
    public DataResponseMessage<List<ReceivedFriendRequestDTO>> getReceivedFriendRequests(String username, Pageable pageable) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);

        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), 10);

        Page<FriendRequest> receivedRequestsPage = friendRequestRepository.findByReceiver(student, pageRequest);

        List<ReceivedFriendRequestDTO> receivedFriendRequestDTOS = receivedRequestsPage.getContent().stream()
                .filter(friendRequest -> friendRequest.getSender().getIsActive())
                .map(friendRequestConverter::receivedToDto)
                .collect(Collectors.toList());

        return new DataResponseMessage<>("Gelen arkadaşlık istekleri başarıyla alındı.", true, receivedFriendRequestDTOS);
    }


    @Override
    public DataResponseMessage<List<SentFriendRequestDTO>> getSentFriendRequests(String username, Pageable pageable) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);

        Pageable pageRequest = PageRequest.of(pageable.getPageNumber(), 10);

        Page<FriendRequest> sentRequestsPage = friendRequestRepository.findBySender(student, pageRequest);

        List<SentFriendRequestDTO> sentFriendRequestDTOS = sentRequestsPage.getContent().stream()
                .filter(friendRequest -> friendRequest.getReceiver().getIsActive())
                .map(friendRequestConverter::sentToDto)
                .collect(Collectors.toList());

        return new DataResponseMessage("Gönderilen arkadaşlık istekleri başarıyla alındı.", true, sentFriendRequestDTOS);
    }


    @Override
    @Transactional
    public ResponseMessage acceptFriendRequest(String username, UUID requestId)
            throws AlreadyAcceptedRequestException, FriendRequestNotFoundException,
            StudentNotFoundException, UnauthorizedRequestException, StudentDeletedException, StudentNotActiveException {

       Student followed = studentRepository.getByUserNumber(username);



        FriendRequest friendRequest = friendRequestRepository.findById(requestId)
                .orElseThrow(FriendRequestNotFoundException::new);

        if (!friendRequest.getReceiver().equals(followed)) {
            throw new UnauthorizedRequestException();
        }

        if (friendRequest.getStatus() == RequestStatus.ACCEPTED) {
            throw new AlreadyAcceptedRequestException();
        }

        Student follower = friendRequest.getSender();

        FollowRelation followRelation = new FollowRelation();
        followRelation.setFollower(follower);
        followRelation.setFollowed(followed);
        followRelation.setFollowingDate(LocalDate.now());

        followed.getFollowers().add(followRelation);
        follower.getFollowing().add(followRelation);

        followRelationRepository.save(followRelation);

        friendRequestRepository.delete(friendRequest);

        studentRepository.save(follower);
        studentRepository.save(followed);

        CreateLogRequest createLogRequest = new CreateLogRequest();
        createLogRequest.setMessage(follower.getUsername() + " seni takip etmeye başladı.");
        createLogRequest.setStudentId(followed.getId());
        logService.addLog(createLogRequest);

        if (followed.getFcmToken() != null) {
            SendNotificationRequest sendNotificationRequest = new SendNotificationRequest();
            sendNotificationRequest.setTitle("Arkadaşlık İsteği Kabul Edildi");
            sendNotificationRequest.setFmcToken(followed.getFcmToken());
            sendNotificationRequest.setMessage(follower.getUsername() + " kullanıcısı isteğini kabul etti.");

            try {
                notificationController.sendToUser(sendNotificationRequest);
            } catch (Exception e) {
                System.err.println("Bildirim gönderme hatası: " + e.getMessage());
            }
        } else {
            System.out.println("Kabul edilen kullanıcının FCM Token değeri bulunamadı!");
        }


        return new ResponseMessage("Arkadaşlık isteği başarıyla kabul edildi.", true);
    }


    @Override
    @Transactional
    public ResponseMessage rejectFriendRequest(String username, UUID requestId) throws AlreadyRejectedRequestException, FriendRequestNotFoundException, StudentNotFoundException, StudentDeletedException, StudentNotActiveException {
        Student student = studentRepository.getByUserNumber(username);


        Optional<FriendRequest> optionalFriendRequest = friendRequestRepository.findById(requestId);
        if (optionalFriendRequest.isEmpty()) {
            throw new FriendRequestNotFoundException();
        }

        FriendRequest friendRequest = optionalFriendRequest.get();

        if (friendRequest.getStatus() == RequestStatus.REJECTED) {
            throw new AlreadyRejectedRequestException();
        }
        Student gönderen = friendRequest.getSender();
        friendRequest.setStatus(RequestStatus.REJECTED);

        student.getReceiverRequest().remove(friendRequest);
        gönderen.getSentRequest().remove(friendRequest);

        friendRequest.getSender().getSentRequest().remove(friendRequest);

        studentRepository.save(student);
        friendRequestRepository.save(friendRequest);

        CreateLogRequest createLogRequest = new CreateLogRequest();
        createLogRequest.setMessage(student.getUsername() + " senin takip isteğini reddetti.");
        createLogRequest.setStudentId(gönderen.getId());
        logService.addLog(createLogRequest);

        return new ResponseMessage("Arkadaşlık isteği başarıyla reddedildi.", true);
    }


    @Override
    public DataResponseMessage<?> getFriendRequestById(String username, UUID requestId) throws UnauthorizedRequestException, FriendRequestNotFoundException, StudentNotFoundException {
        Student alıcı = studentRepository.getByUserNumber(username);

        Optional<FriendRequest> optionalFriendRequest = friendRequestRepository.findById(requestId);
        if (optionalFriendRequest.isEmpty()) {
            throw new FriendRequestNotFoundException();
        }

        FriendRequest friendRequest = optionalFriendRequest.get();

        if (!friendRequest.getSender().getId().equals(alıcı.getId()) &&
                !friendRequest.getReceiver().getId().equals(alıcı.getId())) {
            throw new UnauthorizedRequestException();
        }

        ReceivedFriendRequestDTO receivedDTO = friendRequestConverter.receivedToDto(friendRequest);
        SentFriendRequestDTO sentDTO = friendRequestConverter.sentToDto(friendRequest);

        if (friendRequest.getReceiver().getId().equals(alıcı.getId())) {
            return new DataResponseMessage<>("Gelen arkadaşlık isteği başarıyla getirildi.", true, receivedDTO);
        } else {
            return new DataResponseMessage<>("Gönderilen arkadaşlık isteği başarıyla getirildi.", true, sentDTO);
        }
    }

    @Override
    @Transactional
    public ResponseMessage cancelFriendRequest(String username, UUID requestId) throws FriendRequestNotFoundException, UnauthorizedRequestException, StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);

        Optional<FriendRequest> optionalFriendRequest = friendRequestRepository.findById(requestId);
        if (optionalFriendRequest.isEmpty()) {
            throw new FriendRequestNotFoundException();
        }

        FriendRequest friendRequest = optionalFriendRequest.get();

        if (!friendRequest.getSender().getId().equals(student.getId())) {
            throw new UnauthorizedRequestException();
        }
        student.getSentRequest().remove(friendRequest);
        friendRequest.getReceiver().getReceiverRequest().remove(friendRequest);

        friendRequestRepository.delete(friendRequest);

        studentRepository.save(student);
        student.getSentRequest().remove(friendRequest);
        friendRequest.getReceiver().getReceiverRequest().remove(friendRequest);
        friendRequestRepository.save(friendRequest);

        return new ResponseMessage("Arkadaşlık isteği başarıyla iptal edildi.", true);
    }


    @Override
    public ResponseMessage acceptFriendRequestsBulk(String username, List<UUID> requestIds) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);

        List<UUID> acceptedRequests = new ArrayList<>();
        List<String> failedRequests = new ArrayList<>();

        for (UUID requestId : requestIds) {
            try {
                FriendRequest friendRequest = friendRequestRepository.findById(requestId)
                        .orElseThrow(FriendRequestNotFoundException::new);

                if (!friendRequest.getReceiver().equals(student)) {
                    throw new UnauthorizedRequestException();
                }

                if (friendRequest.getStatus().equals(RequestStatus.ACCEPTED)) {
                    throw new AlreadyAcceptedRequestException();
                }

                acceptFriendRequest(username, friendRequest.getId());

                friendRequestRepository.save(friendRequest);
                acceptedRequests.add(requestId);
            } catch (Exception e) {
                failedRequests.add("Request ID: " + requestId + ", Error: " + e.getMessage());
            }
        }

        return new ResponseMessage(
                "Bulk accept completed. Accepted: " + acceptedRequests.size() + ", Failed: " + failedRequests.size(),
                true
        );
    }

    @Transactional
    @Override
    public ResponseMessage rejectFriendRequestsBulk(String username, List<UUID> requestIds) throws StudentNotFoundException {
        Student receiver = studentRepository.getByUserNumber(username);

        List<UUID> validRequestIds = receiver.getReceiverRequest()
                .stream()
                .map(FriendRequest::getId)
                .toList();

        List<UUID> invalidRequestIds = requestIds.stream()
                .filter(id -> !validRequestIds.contains(id))
                .toList();

        if (!invalidRequestIds.isEmpty()) {
            throw new IllegalArgumentException("Invalid request IDs: " + invalidRequestIds);
        }

        List<FriendRequest> requestsToReject = friendRequestRepository.findAllById(requestIds);
        for (FriendRequest request : requestsToReject) {
            request.setStatus(RequestStatus.REJECTED);
        }

        friendRequestRepository.saveAll(requestsToReject);

        return new ResponseMessage("Successfully rejected " + requestsToReject.size() + " requests", true);
    }


}
