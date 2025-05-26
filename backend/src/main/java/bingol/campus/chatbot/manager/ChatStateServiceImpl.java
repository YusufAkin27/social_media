package bingol.campus.chatbot.manager;

import bingol.campus.chatbot.entity.ChatState;
import bingol.campus.chatbot.manager.ChatStateService;
import org.springframework.stereotype.Service;

import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class ChatStateServiceImpl implements ChatStateService {

    private final Map<Long, ChatState> userStates = new ConcurrentHashMap<>();

    @Override
    public void setState(Long studentId, ChatState state) {
        userStates.put(studentId, state);
    }

    @Override
    public ChatState getState(Long studentId) {
        return userStates.getOrDefault(studentId, ChatState.NONE);
    }
}
