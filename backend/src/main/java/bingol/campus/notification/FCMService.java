package bingol.campus.notification;

import com.google.firebase.messaging.*;
import org.springframework.stereotype.Service;

import java.util.List;

@Service
public class FCMService {

    // Tek bir kullanıcıya bildirim gönderme
    public String sendNotificationToUser(String fcmToken, String title, String body) throws FirebaseMessagingException {
        Notification notification = Notification.builder()
                .setTitle(title)
                .setBody(body)
                .build();

        Message message = Message.builder()
                .setToken(fcmToken)
                .setNotification(notification)
                .build();

        return FirebaseMessaging.getInstance().send(message);
    }

    // Birden fazla kullanıcıya bildirim gönderme (Topic kullanımı)
    public String sendNotificationToTopic(String topic, String title, String body) throws FirebaseMessagingException {
        Notification notification = Notification.builder()
                .setTitle(title)
                .setBody(body)
                .build();

        Message message = Message.builder()
                .setTopic(topic)
                .setNotification(notification)
                .build();

        return FirebaseMessaging.getInstance().send(message);
    }

    // Birden fazla FCM token'a bildirim gönderme (Batch)
    public BatchResponse sendNotificationsToUsers(List<String> fcmTokens, String title, String body) throws FirebaseMessagingException {
        Notification notification = Notification.builder()
                .setTitle(title)
                .setBody(body)
                .build();

        List<Message> messages = fcmTokens.stream()
                .map(token -> Message.builder()
                        .setToken(token)
                        .setNotification(notification)
                        .build())
                .toList();

        return FirebaseMessaging.getInstance().sendAll(messages);
    }
}
