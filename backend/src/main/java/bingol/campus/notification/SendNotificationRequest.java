package bingol.campus.notification;

import bingol.campus.student.entity.Student;
import lombok.Data;

@Data
public class SendNotificationRequest {
    private String fmcToken;
    private String title;
    private String message;

}
