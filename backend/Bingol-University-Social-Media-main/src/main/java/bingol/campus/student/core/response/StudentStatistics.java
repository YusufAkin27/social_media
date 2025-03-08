package bingol.campus.student.core.response;

import lombok.AllArgsConstructor;
import lombok.Builder;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.Map;

@Data
@AllArgsConstructor
@NoArgsConstructor
@Builder
public class StudentStatistics {

    private long totalStudents;
    private long activeStudents;
    private long inactiveStudents;
    private long deletedStudents;
    private Map<String, Long> departmentDistribution; // Departman dağılımı
    private Map<String, Long> facultyDistribution; // Fakülte dağılımı
    private Map<String, Long> genderDistribution; // Cinsiyet dağılımı
    private Map<String, Long> gradeDistribution; // Sınıf durumu

    // Getter ve Setter metodları
}
