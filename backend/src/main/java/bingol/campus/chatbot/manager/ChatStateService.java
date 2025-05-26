package bingol.campus.chatbot.manager;

import bingol.campus.chatbot.entity.ChatState;

public interface ChatStateService {
    void setState(Long studentId, ChatState state);
    ChatState getState(Long studentId);
}
