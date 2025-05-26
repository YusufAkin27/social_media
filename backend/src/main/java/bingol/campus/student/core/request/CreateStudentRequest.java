package bingol.campus.student.core.request;


import bingol.campus.student.entity.enums.Department;
import bingol.campus.student.entity.enums.Faculty;
import bingol.campus.student.entity.enums.Grade;
import lombok.*;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class CreateStudentRequest {
    private String firstName; // Öğrenci Adı
    private String lastName; // Öğrenci Soyadı
    private String username;
    private String password;
    private String email; // E-posta Adresi
    private String mobilePhone; // Telefon Numarası
    private Department department; // Bölüm
    private Faculty faculty; // Fakülte
    private Grade grade; // Sınıf
    private LocalDate birthDate; // Doğum Tarihi
    private Boolean gender; // Cinsiyet (true: Erkek, false: Kadın)


}
