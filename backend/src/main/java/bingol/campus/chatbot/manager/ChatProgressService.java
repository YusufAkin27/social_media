// ChatProgressService - Öğrenci chat sürecini takip etmek için
package bingol.campus.chatbot.manager;

import org.springframework.stereotype.Service;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;

@Service
public class ChatProgressService {

    // Öğrenci chat durumlarını bellekte tutan Map'ler
    private final Map<Long, String> studentDays = new ConcurrentHashMap<>();
    private final Map<Long, Integer> studentTotalLessons = new ConcurrentHashMap<>();
    private final Map<Long, Integer> studentCurrentIndex = new ConcurrentHashMap<>();
    private final Map<Long, Long> currentStudentIds = new ConcurrentHashMap<>();

    /**
     * Öğrencinin seçtiği günü kaydeder
     */
    public void setDay(Long studentId, String dayName) {
        studentDays.put(studentId, dayName);
        currentStudentIds.put(studentId, studentId);
    }

    /**
     * Öğrencinin ekleyeceği toplam ders sayısını kaydeder
     */
    public void setTotalLessons(Long studentId, int count) {
        studentTotalLessons.put(studentId, count);
    }

    /**
     * Öğrencinin şu anki ders sırasını kaydeder
     */
    public void setCurrentLessonIndex(Long studentId, int index) {
        studentCurrentIndex.put(studentId, index);
    }

    /**
     * Öğrencinin şu anki ders sırasını getirir
     */
    public int getCurrentLessonIndex(Long studentId) {
        return studentCurrentIndex.getOrDefault(studentId, 0);
    }

    /**
     * Öğrencinin toplam ders sayısını getirir
     */
    public int getTotalLessons(Long studentId) {
        return studentTotalLessons.getOrDefault(studentId, 0);
    }

    /**
     * Öğrencinin seçtiği günü getirir
     */
    public String getDay(Long studentId) {
        return studentDays.get(studentId);
    }

    /**
     * Öğrencinin ders sırasını bir artırır
     */
    public void incrementLessonIndex(Long studentId) {
        int currentIndex = getCurrentLessonIndex(studentId);
        setCurrentLessonIndex(studentId, currentIndex + 1);
    }

    /**
     * Öğrencinin tüm chat progress verilerini temizler
     */
    public void clear(Long studentId) {
        studentDays.remove(studentId);
        studentTotalLessons.remove(studentId);
        studentCurrentIndex.remove(studentId);
        currentStudentIds.remove(studentId);
    }

    /**
     * Şu anki öğrenci ID'sini getirir
     */
    public Long getCurrentStudentId() {
        // Son işlem yapan öğrencinin ID'sini döndür
        return currentStudentIds.values().stream()
                .findFirst()
                .orElse(null);
    }

    /**
     * Belirli bir öğrencinin chat progress durumunu kontrol eder
     */
    public boolean hasActiveProgress(Long studentId) {
        return studentDays.containsKey(studentId) ||
                studentTotalLessons.containsKey(studentId) ||
                studentCurrentIndex.containsKey(studentId);
    }

    /**
     * Öğrencinin kaç ders daha ekleyeceğini hesaplar
     */
    public int getRemainingLessons(Long studentId) {
        int total = getTotalLessons(studentId);
        int current = getCurrentLessonIndex(studentId);
        return Math.max(0, total - current);
    }

    /**
     * Öğrencinin progress yüzdesini hesaplar
     */
    public double getProgressPercentage(Long studentId) {
        int total = getTotalLessons(studentId);
        int current = getCurrentLessonIndex(studentId);

        if (total == 0) return 0.0;
        return (double) current / total * 100.0;
    }
}

