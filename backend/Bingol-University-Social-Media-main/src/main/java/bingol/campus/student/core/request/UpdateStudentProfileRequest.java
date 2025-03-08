package bingol.campus.student.core.request;

import bingol.campus.student.entity.enums.Department;
import bingol.campus.student.entity.enums.Faculty;
import bingol.campus.student.entity.enums.Grade;
import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.LocalDate;
import java.time.LocalDateTime;

@Data
@Builder
@AllArgsConstructor
@NoArgsConstructor
public class UpdateStudentProfileRequest {

    private String firstName; // Öğrenci Adı
    private String lastName; // Öğrenci Soyadı
    private String mobilePhone; // Telefon Numarası
    private String username;
    private Department department; // Bölüm
    private String biograpy;
    private LocalDate birthDate;
    private Faculty faculty; // Fakülte
    private Grade grade; // Sınıf
    private Boolean gender; // Cinsiyet (true: Erkek, false: Kadın)
}
