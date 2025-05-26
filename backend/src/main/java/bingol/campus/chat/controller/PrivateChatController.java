package bingol.campus.chat.controller;

import bingol.campus.chat.business.abstracts.PrivateChatService;
import bingol.campus.chat.dto.MessageDTO;
import bingol.campus.chat.dto.PrivateChatDTO;
import bingol.campus.chat.exceptions.*;
import bingol.campus.chat.request.EditMessageRequest;
import bingol.campus.chat.request.SendMessageRequest;
import bingol.campus.chat.request.DeleteMessageRequest;
import bingol.campus.chat.request.UpdateMessageStatusRequest;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.student.exceptions.*;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequestMapping("/v1/api/privateChat")
@RequiredArgsConstructor
public class PrivateChatController {

    private final PrivateChatService privateChatService;

    // Yeni özel sohbet oluştur
    @PostMapping("/createChat/{username}")
    public ResponseMessage createChat(@AuthenticationPrincipal UserDetails userDetails, @PathVariable String username)
            throws StudentNotFoundException {
        return privateChatService.createChat(userDetails.getUsername(), username);
    }

    // Mesaj gönder
    @PostMapping("/send")
    public DataResponseMessage<MessageDTO> sendPrivateMessage(@AuthenticationPrincipal UserDetails userDetails,
                                                              @RequestBody SendMessageRequest sendMessageRequest)
            throws StudentNotFoundException, PrivateChatNotFoundException {
        return privateChatService.sendPrivateMessage(userDetails.getUsername(), sendMessageRequest);
    }

    // Mesaj gönder
    @PostMapping("/send/files")
    public DataResponseMessage<MessageDTO> sendPrivateMessageFiles(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestPart("message") SendMessageRequest sendMessageRequest,
            @RequestPart(value = "files", required = false) MultipartFile[] files
    ) throws StudentNotFoundException, PrivateChatNotFoundException, PrivateChatParticipantNotFoundException, OnlyPhotosAndVideosException, PhotoSizeLargerException, IOException, VideoSizeLargerException, FileFormatCouldNotException {
        return privateChatService.sendPrivateFiles(userDetails.getUsername(), sendMessageRequest, files);
    }

    // Kullanıcının sohbetlerini getir
    @GetMapping("/getChats")
    public DataResponseMessage<List<PrivateChatDTO>> getChats(@AuthenticationPrincipal UserDetails userDetails)
            throws StudentNotFoundException {
        return privateChatService.getChats(userDetails.getUsername());
    }

    // Belirli bir sohbetin mesajlarını getir
    @GetMapping("/getMessages/{chatId}")
    public DataResponseMessage<List<MessageDTO>> getMessages(@AuthenticationPrincipal UserDetails userDetails,
                                                             @PathVariable UUID chatId)
            throws StudentNotFoundException, PrivateChatNotFoundException {
        return privateChatService.getMessages(userDetails.getUsername(), chatId);
    }

    // Mesajı düzenle
    @PutMapping("/editMessage")
    public ResponseMessage editMessage(@AuthenticationPrincipal UserDetails userDetails,
                                       @RequestBody EditMessageRequest editMessageRequest) throws MessageNotFoundException, MessageDoesNotBelongStudentException, MessageDoesNotBelongException, StudentNotFoundException, PrivateChatNotFoundException {
        return privateChatService.editMessage(userDetails.getUsername(), editMessageRequest);
    }

    // Mesajı sil (kendinden veya herkesten)
    @DeleteMapping("/deleteMessage")
    public ResponseMessage deleteMessage(@AuthenticationPrincipal UserDetails userDetails,
                                         @RequestBody DeleteMessageRequest deleteMessageRequest) throws MessageNotFoundException, MessageDoesNotBelongStudentException, MessageDoesNotBelongException, StudentNotFoundException, PrivateChatNotFoundException {
        return privateChatService.deleteMessage(userDetails.getUsername(), deleteMessageRequest);
    }

    // Sohbeti sil (kullanıcıdan kaldırma)
    @DeleteMapping("/deleteChat/{chatId}")
    public ResponseMessage deleteChat(@AuthenticationPrincipal UserDetails userDetails,
                                      @PathVariable UUID chatId)
            throws StudentNotFoundException, PrivateChatNotFoundException, ChatNotFoundException {
        return privateChatService.deleteChat(userDetails.getUsername(), chatId);
    }

    // Mesajın kimler tarafından okunduğunu getir
    @GetMapping("/readReceipts/{messageId}")
    public DataResponseMessage<List<String>> getReadReceipts(@AuthenticationPrincipal UserDetails userDetails,
                                                             @PathVariable UUID messageId) throws MessageNotFoundException, MessageNotActiveException, MessageDoesNotBelongStudentException, MessageDeletedException, StudentNotFoundException {
        return privateChatService.getReadReceipts(userDetails.getUsername(), messageId);
    }

    @GetMapping("/userStatus/{username}")
    public DataResponseMessage<Map<String, Object>> getUserStatus(@PathVariable String username) throws StudentNotFoundException {
        return privateChatService.getUserStatus(username);
    }

    @PutMapping("/updateMessageStatus")
    public ResponseMessage updateMessageStatus(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestBody UpdateMessageStatusRequest updateMessageStatusRequest) {
        return privateChatService.updateMessageStatus(userDetails.getUsername(), updateMessageStatusRequest);
    }

    @PutMapping("/archiveChat/{chatId}")
    public ResponseMessage archiveChat(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID chatId) throws AlreadyArchiveChatException, StudentNotFoundException, PrivateChatNotFoundException {
        return privateChatService.archiveChat(userDetails.getUsername(), chatId);
    }

    @PutMapping("/pinChat/{chatId}")
    public ResponseMessage pinChat(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID chatId) throws AlreadyPinnedChatException, StudentNotFoundException, PrivateChatNotFoundException {
        return privateChatService.pinChat(userDetails.getUsername(), chatId);
    }

    @DeleteMapping("/pinChat/{chatId}")
    public ResponseMessage unpinChat(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID chatId) throws StudentNotFoundException, PrivateChatNotFoundException {
        return privateChatService.unpinChat(userDetails.getUsername(), chatId);
    }

    @DeleteMapping("/archiveChat/{chatId}")
    public ResponseMessage unarchiveChat(@AuthenticationPrincipal UserDetails userDetails, @PathVariable UUID chatId) throws StudentNotFoundException, PrivateChatNotFoundException {
        return privateChatService.unarchiveChat(userDetails.getUsername(), chatId);
    }
}
