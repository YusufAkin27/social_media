package bingol.campus.chat.listener;

import bingol.campus.chat.service.OnlineUserTracker;
import bingol.campus.student.entity.Student;
import bingol.campus.student.exceptions.StudentNotFoundException;
import bingol.campus.student.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.event.EventListener;
import org.springframework.messaging.simp.stomp.StompHeaderAccessor;
import org.springframework.stereotype.Component;
import org.springframework.web.socket.messaging.SessionConnectedEvent;
import org.springframework.web.socket.messaging.SessionDisconnectEvent;

import java.time.LocalDateTime;
import java.util.Optional;

@Component
@RequiredArgsConstructor
public class WebSocketEventListener {

    private static final Logger logger = LoggerFactory.getLogger(WebSocketEventListener.class);
    private final OnlineUserTracker onlineUserTracker;
    private final StudentRepository studentRepository;

    @EventListener
    public void handleWebSocketConnectListener(SessionConnectedEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        String username = (String) headerAccessor.getSessionAttributes().get("username");

        if (username != null) {
            onlineUserTracker.addUser(username);
            logger.info("Kullanıcı bağlandı: " + username);

            Optional<Student> studentOpt = studentRepository.findByUserNumber(username);
            if (studentOpt.isPresent()) {
                Student student = studentOpt.get();
                student.setIsOnline(true);
                studentRepository.save(student);
            } else {
                logger.warn("Bağlanan kullanıcı veritabanında bulunamadı: " + username);
            }
        }
    }

    @EventListener
    public void handleWebSocketDisconnectListener(SessionDisconnectEvent event) {
        StompHeaderAccessor headerAccessor = StompHeaderAccessor.wrap(event.getMessage());
        String username = (String) headerAccessor.getSessionAttributes().get("username");

        if (username != null) {
            onlineUserTracker.removeUser(username);
            logger.info("Kullanıcı ayrıldı: " + username);

            Optional<Student> studentOpt = studentRepository.findByUserNumber(username);
            if (studentOpt.isPresent()) {
                Student student = studentOpt.get();
                student.setIsOnline(false);
                if (Boolean.TRUE.equals(student.getShowLastSeen())) {
                    student.setLastSeenAt(LocalDateTime.now());
                }
                studentRepository.save(student);
            } else {
                logger.warn("Ayrılan kullanıcı veritabanında bulunamadı: " + username);
            }
        }
    }
}
