package bingol.campus.notification;

import com.google.firebase.messaging.BatchResponse;
import com.google.firebase.messaging.FirebaseMessagingException;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;

@RestController
@RequestMapping("/v1/api/notifications")
@RequiredArgsConstructor
public class NotificationController {

    private final FCMService fcmService;

    // ✅ Tek bir kullanıcıya bildirim gönderme (FCM Token ile)
    @PostMapping("/send-to-user")
    public ResponseEntity<String> sendToUser(@RequestBody SendNotificationRequest sendNotificationRequest) {
        try {
            String response = fcmService.sendNotificationToUser(sendNotificationRequest.getFmcToken(), sendNotificationRequest.getTitle(), sendNotificationRequest.getMessage());
            return ResponseEntity.ok("Bildirim başarıyla gönderildi! ID: " + response);
        } catch (FirebaseMessagingException e) {
            return ResponseEntity.status(500).body("Hata: " + e.getMessage());
        }
    }

    // ✅ Birden fazla kullanıcıya bildirim gönderme (FCM Token listesi ile)
    @PostMapping("/send-to-users")
    public ResponseEntity<String> sendToUsers(@RequestBody SendBulkNotificationRequest sendBulkNotificationRequest) {
        try {
            BatchResponse response = fcmService.sendNotificationsToUsers(sendBulkNotificationRequest.getFmcTokens(), sendBulkNotificationRequest.getTitle(), sendBulkNotificationRequest.getMessage());
            return ResponseEntity.ok("Başarıyla gönderilen bildirim sayısı: " + response.getSuccessCount());
        } catch (Exception e) {
            return ResponseEntity.status(500).body("Hata: " + e.getMessage());
        }
    }

    // ✅ Bir konuya (topic) bildirim gönderme
    @PostMapping("/send-to-topic")
    public ResponseEntity<String> sendToTopic(@RequestParam String topic,
                                              @RequestParam String title,
                                              @RequestParam String body) {
        try {
            String response = fcmService.sendNotificationToTopic(topic, title, body);
            return ResponseEntity.ok("Topic '" + topic + "' için bildirim başarıyla gönderildi! ID: " + response);
        } catch (FirebaseMessagingException e) {
            return ResponseEntity.status(500).body("Hata: " + e.getMessage());
        }
    }
}
