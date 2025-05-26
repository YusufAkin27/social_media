package bingol.campus.chat.converter;

import bingol.campus.chat.dto.MessageDTO;
import bingol.campus.chat.dto.PrivateChatDTO;
import bingol.campus.chat.entity.Message;
import bingol.campus.chat.entity.PrivateChat;
import org.springframework.stereotype.Component;

@Component
public class ChatConverterImpl implements ChatConverter {
    @Override
    public MessageDTO toMessageDTO(Message message) {
        if (message==null){
            return null;
        }
        long receiverId = 0;

        // Eğer mesajın ait olduğu sohbet PrivateChat ise, alıcıyı belirle
        if (message.getChat() instanceof PrivateChat) {
            PrivateChat privateChat = (PrivateChat) message.getChat();
            if (privateChat.getSender().getStudent().getId().equals(message.getSender().getId())) {
                receiverId = privateChat.getReceiver().getStudent().getId();
            } else {
                receiverId = privateChat.getSender().getStudent().getId();
            }
        }

        return MessageDTO.builder()
                .chatId(message.getChat().getId())
                .messageId(message.getId())
                .content(message.getContent())
                .senderUsername(message.getSender().getUsername())
                .receiverId(receiverId)
                .sentAt(message.getCreatedAt())
                .updatedAt(message.getUpdatedAt())
                .isPinned(message.getIsPinned())
                .isDeleted(message.getIsDeleted())
                .build();
    }

    @Override
    public PrivateChatDTO toPrivateChatDTO(PrivateChat privateChat) {
        return PrivateChatDTO.builder()
                .username1(privateChat.getSender().getStudent().getUsername())
                .chatId(privateChat.getId())
                .chatName(privateChat.getChatName())
                .lastEndMessage(privateChat.getMessages() != null && !privateChat.getMessages().isEmpty() ? toMessageDTO(privateChat.getMessages().getLast()) : null)                .username2(privateChat.getReceiver().getStudent().getUsername())
                .chatPhoto(privateChat.getChatPhoto())
                .build();
    }
}
