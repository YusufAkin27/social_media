package bingol.campus.mailservice;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.io.File;
import java.util.List;
@Data
@AllArgsConstructor
@NoArgsConstructor
public class EmailMessage {
    private String toEmail;
    private String subject;
    private String body;
    private boolean isHtml;


}
