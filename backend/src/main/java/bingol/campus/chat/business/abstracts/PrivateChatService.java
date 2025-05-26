package bingol.campus.chat.business.abstracts;

import bingol.campus.chat.dto.MessageDTO;
import bingol.campus.chat.exceptions.*;
import bingol.campus.chat.request.DeleteMessageRequest;
import bingol.campus.chat.request.EditMessageRequest;
import bingol.campus.chat.request.SendMessageRequest;
import bingol.campus.chat.request.UpdateMessageStatusRequest;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.student.exceptions.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.util.List;
import java.util.Map;
import java.util.UUID;

public interface PrivateChatService {
    DataResponseMessage sendPrivateMessage(String username, SendMessageRequest sendMessageRequest) throws StudentNotFoundException, PrivateChatNotFoundException;

    ResponseMessage createChat(String username, String username1) throws StudentNotFoundException;

    DataResponseMessage getChats(String username) throws StudentNotFoundException;

    DataResponseMessage getMessages(String username, UUID chatId) throws StudentNotFoundException, PrivateChatNotFoundException;

    DataResponseMessage<Map<String, Object>> getUserStatus(String username) throws StudentNotFoundException;

    ResponseMessage editMessage(String username, EditMessageRequest editMessageRequest) throws MessageNotFoundException, StudentNotFoundException, PrivateChatNotFoundException, MessageDoesNotBelongException, MessageDoesNotBelongStudentException;

    ResponseMessage deleteMessage(String username, DeleteMessageRequest deleteMessageRequest) throws MessageDoesNotBelongStudentException, MessageDoesNotBelongException, StudentNotFoundException, MessageNotFoundException, PrivateChatNotFoundException;

    ResponseMessage deleteChat(String username, UUID chatId) throws ChatNotFoundException, StudentNotFoundException;

    DataResponseMessage<List<String>> getReadReceipts(String username, UUID messageId) throws StudentNotFoundException, MessageNotFoundException, MessageDoesNotBelongStudentException, MessageNotActiveException, MessageDeletedException;

    DataResponseMessage<MessageDTO> sendPrivateFiles(String username, SendMessageRequest sendMessageRequest, MultipartFile[] files) throws PrivateChatNotFoundException, StudentNotFoundException, PrivateChatParticipantNotFoundException, OnlyPhotosAndVideosException, PhotoSizeLargerException, IOException, VideoSizeLargerException, FileFormatCouldNotException;

    ResponseMessage updateMessageStatus(String username, UpdateMessageStatusRequest updateMessageStatusRequest);

    ResponseMessage archiveChat(String username, UUID chatId) throws PrivateChatNotFoundException, StudentNotFoundException, AlreadyArchiveChatException;

    ResponseMessage pinChat(String username, UUID chatId) throws StudentNotFoundException, PrivateChatNotFoundException, AlreadyPinnedChatException;

    ResponseMessage unpinChat(String username, UUID chatId);

    ResponseMessage unarchiveChat(String username, UUID chatId);
}
