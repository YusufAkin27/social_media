package bingol.campus.chat.converter;

import bingol.campus.chat.dto.MessageDTO;
import bingol.campus.chat.dto.PrivateChatDTO;
import bingol.campus.chat.entity.Message;
import bingol.campus.chat.entity.PrivateChat;

public interface ChatConverter {
    MessageDTO toMessageDTO(Message message);

    PrivateChatDTO toPrivateChatDTO(PrivateChat privateChat);
}
