package bingol.campus.chat.business.concretes;

import bingol.campus.chat.business.abstracts.PrivateChatService;
import bingol.campus.chat.converter.ChatConverter;
import bingol.campus.chat.dto.MessageDTO;
import bingol.campus.chat.dto.PrivateChatDTO;
import bingol.campus.chat.entity.*;
import bingol.campus.chat.exceptions.*;
import bingol.campus.chat.repository.*;
import bingol.campus.chat.request.DeleteMessageRequest;
import bingol.campus.chat.request.EditMessageRequest;
import bingol.campus.chat.request.SendMessageRequest;
import bingol.campus.chat.request.UpdateMessageStatusRequest;
import bingol.campus.config.MediaUploadService;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.student.entity.Student;
import bingol.campus.student.exceptions.*;
import bingol.campus.student.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDateTime;
import java.util.*;
import java.util.concurrent.CompletableFuture;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class PrivateChatManager implements PrivateChatService {
    private final ChatRepository chatRepository;
    private final StudentRepository studentRepository;
    private final MessageRepository messageRepository;
    private final PrivateChatRepository privateChatRepository;
    private final ChatConverter chatConverter;
    private final ChatParticipantRepository chatParticipantRepository;
    private final NotificationRepository notificationRepository;
    private final SimpMessagingTemplate messagingTemplate;
    private final MediaUploadService mediaUploadService;

    @Override
    public DataResponseMessage sendPrivateMessage(String username, SendMessageRequest sendMessageRequest) throws StudentNotFoundException, PrivateChatNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        PrivateChat privateChat = privateChatRepository.findById(sendMessageRequest.getChatId()).orElseThrow(PrivateChatNotFoundException::new);
        Message message = new Message();
        message.setChat(privateChat);
        message.setContent(sendMessageRequest.getContent());
        message.setCreatedAt(LocalDateTime.now());
        message.setSender(student);
        message.setIsDeleted(false);
        message.setIsPinned(false);
        message.setMediaUrls(null);
        message.setSeenBy(null);
        message.setUpdatedAt(null);
        messageRepository.save(message);
        privateChat.getMessages().add(message);
        Notification notification = new Notification();
        notification.setChat(privateChat);
        notification.setSender(student);
        notification.setReceiver(privateChat.getSender().getStudent().equals(student) ? privateChat.getReceiver().getStudent() : privateChat.getSender().getStudent());
        notification.setCreatedAt(LocalDateTime.now());
        notification.setContent(message.getContent());
        notification.setIsRead(false);
        notificationRepository.save(notification);
        privateChatRepository.save(privateChat);
        MessageDTO messageDTO = chatConverter.toMessageDTO(message);

        student.getPrivateChats().add(privateChat);
        messagingTemplate.convertAndSend("/topic/privateChat." + privateChat.getId(), messageDTO);


        return new DataResponseMessage("Message sent successfully", true, messageDTO);
    }

    @Override
    @Transactional
    public ResponseMessage createChat(String username, String username1) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        Student student1 = studentRepository.getByUserNumber(username1);

        // 1️⃣ **PrivateChat nesnesini oluştur (Henüz kaydetme)**
        PrivateChat privateChat = new PrivateChat();
        privateChat.setChatName(student.getFirstName() + " " + student.getLastName() + " - " + student1.getFirstName() + " " + student1.getLastName());
        privateChat.setCreatedAt(LocalDateTime.now());
        privateChat.setUpdatedAt(LocalDateTime.now());
        privateChat = privateChatRepository.saveAndFlush(privateChat);


        // 2️⃣ **ChatParticipant nesnelerini oluştur**
        ChatParticipant participant1 = new ChatParticipant();
        participant1.setChat(privateChat); // 🔥 Chat bağlantısını ekliyoruz
        participant1.setStudent(student);
        participant1.setIsAdmin(false);
        participant1.setNotificationsEnabled(false);
        participant1.setLastSeenAt(student.getLastSeenAt());

        ChatParticipant participant2 = new ChatParticipant();
        participant2.setChat(privateChat); // 🔥 Chat bağlantısını ekliyoruz
        participant2.setStudent(student1);
        participant2.setIsAdmin(false);
        participant2.setNotificationsEnabled(false);
        participant2.setLastSeenAt(student1.getLastSeenAt());

        // 3️⃣ **Katılımcıları önce kaydet**
        participant1 = chatParticipantRepository.save(participant1);
        participant2 = chatParticipantRepository.save(participant2);

        // 4️⃣ **PrivateChat nesnesini güncelle ve KAYDET**
        privateChat.setSender(participant1);
        privateChat.setReceiver(participant2);
        privateChatRepository.save(privateChat); // 🔥 Artık NULL değil
        student.getPrivateChats().add(privateChat);
        student1.getPrivateChats().add(privateChat);
        studentRepository.save(student);


        return new ResponseMessage("Chat created successfully", true);
    }


    @Override
    public DataResponseMessage getChats(String username) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        List<PrivateChatDTO> privateChatDTOS = student.getPrivateChats().stream().map(chatConverter::toPrivateChatDTO).toList();
        return new DataResponseMessage("Private chats fetched successfully", true, privateChatDTOS);
    }

    @Override
    public DataResponseMessage getMessages(String username, UUID chatId) throws StudentNotFoundException, PrivateChatNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        PrivateChat privateChat = student.getPrivateChats().stream().filter(p -> p.getId().equals(chatId)).findFirst().orElseThrow(PrivateChatNotFoundException::new);
        List<MessageDTO> messageDTOS = privateChat.getMessages().stream().map(chatConverter::toMessageDTO).toList();
        return new DataResponseMessage("Messages fetched successfully", true, messageDTOS);
    }

    @Override
    public DataResponseMessage<Map<String, Object>> getUserStatus(String username) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);


        Map<String, Object> response = new HashMap<>();

        if (Boolean.TRUE.equals(student.getIsOnline())) {
            response.put("status", "Online");
        } else if (Boolean.TRUE.equals(student.getShowLastSeen()) && student.getLastSeenAt() != null) {
            response.put("status", "Son görülme: " + student.getLastSeenAt());
        } else {
            response.put("status", "Offline");
        }

        return new DataResponseMessage<>("Kullanıcı durumu getirildi", true, response);
    }

    @Override
    @Transactional
    public ResponseMessage editMessage(String username, EditMessageRequest editMessageRequest) throws MessageNotFoundException, StudentNotFoundException, PrivateChatNotFoundException, MessageDoesNotBelongException, MessageDoesNotBelongStudentException {
        Student student = studentRepository.getByUserNumber(username);
        Message message = messageRepository.findById(editMessageRequest.getMessageId()).orElseThrow(MessageNotFoundException::new);
        PrivateChat privateChat = privateChatRepository.findById(editMessageRequest.getChatId()).orElseThrow(PrivateChatNotFoundException::new);

        if (!message.getChat().getId().equals(privateChat.getId())) {
            throw new MessageDoesNotBelongException();
        }
        if (!message.getSender().equals(student)) {
            throw new MessageDoesNotBelongStudentException();
        }

        message.setContent(editMessageRequest.getContent());
        message.setUpdatedAt(LocalDateTime.now());
        message.setIsEdited(true);
        return new ResponseMessage("Message edited successfully", true);
    }

    @Override
    @Transactional
    public ResponseMessage deleteMessage(String username, DeleteMessageRequest deleteMessageRequest) throws MessageDoesNotBelongStudentException, MessageDoesNotBelongException, StudentNotFoundException, MessageNotFoundException, PrivateChatNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        Message message = messageRepository.findById(deleteMessageRequest.getMessageId()).orElseThrow(MessageNotFoundException::new);
        PrivateChat privateChat = privateChatRepository.findById(deleteMessageRequest.getChatId()).orElseThrow(PrivateChatNotFoundException::new);
        if (!message.getChat().getId().equals(privateChat.getId())) {
            throw new MessageDoesNotBelongException();
        }
        if (!message.getSender().equals(student)) {
            throw new MessageDoesNotBelongStudentException();
        }
        message.setIsDeleted(true);
        message.setIsActive(false);
        //kullanıcı yalnızca aktif mesajları görebilir
        return new ResponseMessage("Message deleted successfully", true);
    }

    @Override
    @Transactional
    public ResponseMessage deleteChat(String username, UUID chatId) throws ChatNotFoundException, StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        Chat chat = chatRepository.findById(chatId).orElseThrow(ChatNotFoundException::new);
        if (student.getChatParticipants().stream().filter(p -> p.getChat().getId().equals(chatId)).findFirst().isEmpty()) {
            throw new ChatNotFoundException();
        }
        student.getGroupChats().removeIf(p -> p.getId().equals(chatId));
        student.getPrivateChats().removeIf(p -> p.getId().equals(chatId));
        student.getPinnedChats().removeIf(p -> p.getId().equals(chatId));
        student.getArchiveChats().removeIf(p -> p.getId().equals(chatId));
        return new ResponseMessage("Chat deleted successfully", true);
    }

    @Override
    public DataResponseMessage<List<String>> getReadReceipts(String username, UUID messageId) throws StudentNotFoundException, MessageNotFoundException, MessageDoesNotBelongStudentException, MessageNotActiveException, MessageDeletedException {
        Student student = studentRepository.getByUserNumber(username);
        Message message = messageRepository.findById(messageId).orElseThrow(MessageNotFoundException::new);
        if (!message.getSender().equals(student)) {
            throw new MessageDoesNotBelongStudentException();
        }
        if (!message.getIsActive()) {
            throw new MessageNotActiveException();
        }
        if (message.getIsDeleted()) {
            throw new MessageDeletedException();
        }

        List<String> usernames = new ArrayList<>();
        for (Long id : message.getSeenBy()) {
            usernames.add(Objects.requireNonNull(studentRepository.findById(id).orElse(null)).getUserNumber());
        }

        return new DataResponseMessage<>("Read receipts fetched successfully", true, usernames);
    }

    @Override
    @Transactional
    public DataResponseMessage<MessageDTO> sendPrivateFiles(String username, SendMessageRequest sendMessageRequest, MultipartFile[] files) throws PrivateChatNotFoundException, StudentNotFoundException, PrivateChatParticipantNotFoundException, OnlyPhotosAndVideosException, PhotoSizeLargerException, IOException, VideoSizeLargerException, FileFormatCouldNotException {
        Student student = studentRepository.getByUserNumber(username);
        PrivateChat privateChat = privateChatRepository.findById(sendMessageRequest.getChatId()).orElseThrow(PrivateChatNotFoundException::new);
        if (student.getChatParticipants().stream().filter(p -> p.getChat().getId().equals(privateChat.getId())).findFirst().isEmpty()) {
            throw new PrivateChatParticipantNotFoundException();
        }
        List<CompletableFuture<String>> mediaUrls = new ArrayList<>();
        for (MultipartFile file : files) {
            mediaUrls.add(mediaUploadService.uploadAndOptimizeMedia(file));
        }
        List<String> uploadedUrls = mediaUrls.stream()
                .map(CompletableFuture::join)
                .toList();
        Message message = new Message();
        message.setChat(privateChat);
        message.setSender(student);
        message.setContent(sendMessageRequest.getContent());
        message.setMediaUrls(uploadedUrls);
        message.setCreatedAt(LocalDateTime.now());
        student.getMessages().add(message);
        privateChat.getMessages().add(message);
        messageRepository.save(message);
        privateChatRepository.save(privateChat);
        return new DataResponseMessage<>("Files sent successfully", true, chatConverter.toMessageDTO(message));
    }

    @Override
    public ResponseMessage updateMessageStatus(String username, UpdateMessageStatusRequest updateMessageStatusRequest) {
        return null;
    }

    @Override
    @Transactional
    public ResponseMessage archiveChat(String username, UUID chatId) throws PrivateChatNotFoundException, StudentNotFoundException, AlreadyArchiveChatException {
        Student student = studentRepository.getByUserNumber(username);
        PrivateChat privateChat = privateChatRepository.findById(chatId).orElseThrow(PrivateChatNotFoundException::new);
        if (student.getArchiveChats().contains(privateChat)) {
            throw new AlreadyArchiveChatException();
        }
        student.getArchiveChats().add(privateChat);
        return new ResponseMessage("sohbet arşivlendi", true);
    }

    @Override
    @Transactional
    public ResponseMessage pinChat(String username, UUID chatId) throws StudentNotFoundException, PrivateChatNotFoundException, AlreadyPinnedChatException {
        Student student = studentRepository.getByUserNumber(username);
        PrivateChat privateChat = privateChatRepository.findById(chatId).orElseThrow(PrivateChatNotFoundException::new);
        if (student.getPinnedChats().contains(privateChat)) {
            throw new AlreadyPinnedChatException();
        }
        student.getPinnedChats().add(privateChat);
        return new ResponseMessage("sohbet sabitlendi", true);
    }

    @Override
    public ResponseMessage unpinChat(String username, UUID chatId) {
        return null;
    }

    @Override
    public ResponseMessage unarchiveChat(String username, UUID chatId) {
        return null;
    }


}
