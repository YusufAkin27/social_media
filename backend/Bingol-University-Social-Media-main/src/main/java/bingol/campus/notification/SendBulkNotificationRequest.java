package bingol.campus.notification;

import lombok.Data;

import java.util.List;

@Data
public class SendBulkNotificationRequest {
    private List<String>fmcTokens;
    private String title;
    private String message;
}
