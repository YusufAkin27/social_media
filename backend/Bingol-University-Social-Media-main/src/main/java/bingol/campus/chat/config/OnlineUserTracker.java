package bingol.campus.chat.service;

import lombok.Getter;
import org.springframework.stereotype.Service;

import java.util.Set;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class OnlineUserTracker {

    @Getter
    private final Set<String> onlineUsers = ConcurrentHashMap.newKeySet();

    public void addUser(String username) {
        onlineUsers.add(username);
    }

    public void removeUser(String username) {
        onlineUsers.remove(username);
    }

    public boolean isUserOnline(String username) {
        return onlineUsers.contains(username);
    }
}
