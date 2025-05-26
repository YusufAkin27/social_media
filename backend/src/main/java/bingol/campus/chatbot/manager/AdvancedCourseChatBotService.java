package bingol.campus.chatbot.manager;

import bingol.campus.chatbot.entity.ChatState;
import bingol.campus.chatbot.entity.Course;
import bingol.campus.student.entity.Student;
import org.springframework.stereotype.Service;
import java.time.DayOfWeek;
import java.time.LocalTime;
import java.time.format.DateTimeFormatter;
import java.time.format.DateTimeParseException;
import java.util.List;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

@Service
public class AdvancedCourseChatBotService {

    private final ChatStateService chatStateService;
    private final ChatProgressService chatProgressService;
    private final CourseService courseService;

    // Gelişmiş regex pattern'ları
    private final Pattern dersPattern = Pattern.compile(
            "(?<isim>[^0-9:]+?)\\s+(?<baslangic>\\d{1,2}[:.:]\\d{2})\\s*[-–—]\\s*(?<bitis>\\d{1,2}[:.:]\\d{2})"
    );

    private final Pattern saatPattern = Pattern.compile("\\d{1,2}[:.:]\\d{2}");

    public AdvancedCourseChatBotService(ChatStateService chatStateService,
                                        ChatProgressService chatProgressService,
                                        CourseService courseService) {
        this.chatStateService = chatStateService;
        this.chatProgressService = chatProgressService;
        this.courseService = courseService;
    }

    public String processMessage(Student student, String message) {
        ChatState chatState = chatStateService.getState(student.getId());
        String normalizedMessage = message.trim().toLowerCase();

        try {
            // Yardım komutu
            if (normalizedMessage.matches(".*(yardım|help|komut).*")) {
                return getHelpMessage();
            }

            // Mevcut programa bakma
            if (normalizedMessage.matches(".*(program.*gör|programa.*bak|ders.*listesi|mevcut.*ders).*")) {
                return showCurrentSchedule(student);
            }

            // Ders kaydı başlatılıyor mu?
            if (normalizedMessage.matches(".*(ders.*kayıt|ders.*ekle|ders.*program.*oluştur|ders.*program.*yap|yeni.*ders).*")) {
                chatStateService.setState(student.getId(), ChatState.DERS_KAYDI_ONAY_BEKLENIYOR);
                return buildConfirmationMessage();
            }

            return handleStateBasedMessage(student, message, chatState);

        } catch (Exception e) {
            resetChatState(student.getId());
            return "❌ Bir hata oluştu. Lütfen tekrar deneyin. Yardım için 'yardım' yazabilirsiniz.";
        }
    }

    private String handleStateBasedMessage(Student student, String message, ChatState chatState) {
        switch (chatState) {
            case DERS_KAYDI_ONAY_BEKLENIYOR:
                return handleConfirmation(student, message);

            case GUN_BEKLENIYOR:
                return handleDaySelection(student, message);

            case DERS_SAYISI_BEKLENIYOR:
                return handleLessonCount(student, message);

            case DERS_BILGISI_BEKLENIYOR:
                return handleLessonInfo(student, message);

            default:
                return getWelcomeMessage();
        }
    }

    private String handleConfirmation(Student student, String message) {
        String normalized = message.trim().toLowerCase();

        if (normalized.matches(".*(evet|yes|tamam|ok|başla).*")) {
            chatStateService.setState(student.getId(), ChatState.GUN_BEKLENIYOR);
            return buildDaySelectionMessage();
        } else if (normalized.matches(".*(hayır|no|iptal|vazgeç).*")) {
            resetChatState(student.getId());
            return "✅ Ders kaydı iptal edildi. Başka bir şey için yardıma ihtiyacınız varsa 'yardım' yazabilirsiniz.";
        } else {
            return "❓ Lütfen 'Evet' veya 'Hayır' şeklinde yanıtlayın.";
        }
    }

    private String handleDaySelection(Student student, String message) {
        String day = message.trim();

        // Türkçe gün isimlerini normalize et
        DayOfWeek dayOfWeek = parseTurkishDay(day);

        if (dayOfWeek == null) {
            return "❌ Geçersiz gün ismi. Lütfen şu formatlardan birini kullanın:\n" +
                    "📅 Pazartesi, Salı, Çarşamba, Perşembe, Cuma, Cumartesi, Pazar";
        }

        // Eğer o gün için zaten ders varsa uyar
        List<Course> existingCourses = courseService.getCoursesByStudentAndDay(student.getId(), dayOfWeek);
        if (!existingCourses.isEmpty()) {
            return String.format("⚠️ %s günü için zaten %d ders kaydınız var.\n" +
                            "Yine de devam etmek istiyor musunuz? (Evet/Hayır)\n" +
                            "Mevcut dersler: %s",
                    getDayNameInTurkish(dayOfWeek),
                    existingCourses.size(),
                    formatCourseList(existingCourses));
        }

        chatProgressService.setDay(student.getId(), dayOfWeek.name());
        chatStateService.setState(student.getId(), ChatState.DERS_SAYISI_BEKLENIYOR);

        return String.format("✅ %s günü seçildi.\n📊 Bu gün için kaç ders eklemek istersiniz? (1-8 arası)",
                getDayNameInTurkish(dayOfWeek));
    }

    private String handleLessonCount(Student student, String message) {
        try {
            int count = Integer.parseInt(message.trim());

            if (count < 1 || count > 8) {
                return "❌ Ders sayısı 1 ile 8 arasında olmalıdır. Lütfen geçerli bir sayı girin.";
            }

            chatProgressService.setTotalLessons(student.getId(), count);
            chatProgressService.setCurrentLessonIndex(student.getId(), 0);
            chatStateService.setState(student.getId(), ChatState.DERS_BILGISI_BEKLENIYOR);

            return buildFirstLessonPrompt();

        } catch (NumberFormatException e) {
            return "❌ Lütfen geçerli bir sayı girin (1-8 arası).";
        }
    }

    private String handleLessonInfo(Student student, String message) {
        int currentIndex = chatProgressService.getCurrentLessonIndex(student.getId());
        int totalLessons = chatProgressService.getTotalLessons(student.getId());
        String dayString = chatProgressService.getDay(student.getId());
        DayOfWeek day = DayOfWeek.valueOf(dayString);

        Matcher matcher = dersPattern.matcher(message.trim());

        if (!matcher.find()) {
            return buildInvalidFormatMessage(currentIndex + 1);
        }

        String courseName = matcher.group("isim").trim();
        String startTimeStr = matcher.group("baslangic").replace(":", ":");
        String endTimeStr = matcher.group("bitis").replace(":", ":");

        try {
            LocalTime startTime = parseTime(startTimeStr);
            LocalTime endTime = parseTime(endTimeStr);

            // Saat kontrolü
            if (startTime.isAfter(endTime) || startTime.equals(endTime)) {
                return "❌ Başlangıç saati bitiş saatinden önce olmalıdır. Lütfen tekrar girin.";
            }

            // Çakışma kontrolü
            if (courseService.hasTimeConflict(student.getId(), day, startTime, endTime)) {
                return "⚠️ Bu saat aralığında zaten bir dersiniz var. Farklı bir saat aralığı seçin.";
            }

            // Dersi kaydet
            courseService.saveCourse(student.getId(), day, courseName, startTime, endTime);
            chatProgressService.incrementLessonIndex(student.getId());

            if (currentIndex + 1 < totalLessons) {
                return buildNextLessonPrompt(currentIndex + 2, totalLessons);
            } else {
                return buildCompletionMessage(day, totalLessons);
            }

        } catch (DateTimeParseException e) {
            return "❌ Geçersiz saat formatı. Lütfen HH:MM formatında girin (örn: 09:00).";
        }
    }

    // Yardımcı metodlar
    private DayOfWeek parseTurkishDay(String day) {
        String normalized = day.toLowerCase().trim();
        switch (normalized) {
            case "pazartesi": case "pzt": return DayOfWeek.MONDAY;
            case "salı": case "sali": case "sl": return DayOfWeek.TUESDAY;
            case "çarşamba": case "carsamba": case "çar": case "car": return DayOfWeek.WEDNESDAY;
            case "perşembe": case "persembe": case "per": return DayOfWeek.THURSDAY;
            case "cuma": case "cm": return DayOfWeek.FRIDAY;
            case "cumartesi": case "cmt": return DayOfWeek.SATURDAY;
            case "pazar": case "paz": return DayOfWeek.SUNDAY;
            default: return null;
        }
    }

    private String getDayNameInTurkish(DayOfWeek day) {
        switch (day) {
            case MONDAY: return "Pazartesi";
            case TUESDAY: return "Salı";
            case WEDNESDAY: return "Çarşamba";
            case THURSDAY: return "Perşembe";
            case FRIDAY: return "Cuma";
            case SATURDAY: return "Cumartesi";
            case SUNDAY: return "Pazar";
            default: return day.name();
        }
    }

    private LocalTime parseTime(String timeStr) {
        String normalized = timeStr.replace(".", ":").replace(",", ":");
        if (normalized.length() == 4 && !normalized.contains(":")) {
            normalized = normalized.substring(0, 2) + ":" + normalized.substring(2);
        }
        return LocalTime.parse(normalized, DateTimeFormatter.ofPattern("H:mm"));
    }

    private void resetChatState(Long studentId) {
        chatStateService.setState(studentId, ChatState.NONE);
        chatProgressService.clear(studentId);
    }

    // Mesaj oluşturma metodları
    private String getWelcomeMessage() {
        return "👋 Merhaba! Ders programı asistanınızım.\n\n" +
                "🔹 Ders eklemek için: 'ders ekle' veya 'ders kaydı'\n" +
                "🔹 Programınızı görmek için: 'programımı göster'\n" +
                "🔹 Yardım için: 'yardım'\n\n" +
                "Nasıl yardımcı olabilirim? 😊";
    }

    private String getHelpMessage() {
        return "🆘 **YARDIM MENÜSÜ**\n\n" +
                "📝 **Ders Ekleme:**\n" +
                "• 'ders ekle', 'ders kaydı', 'yeni ders'\n\n" +
                "📋 **Program Görüntüleme:**\n" +
                "• 'programımı göster', 'ders listesi'\n\n" +
                "⏰ **Saat Formatı:**\n" +
                "• 09:00-10:30 veya 9:00-10:30\n\n" +
                "📅 **Gün Formatı:**\n" +
                "• Pazartesi, Salı, Çarşamba, vb.\n\n" +
                "💡 **İpucu:** Her adımda açık talimatlar vereceğim!";
    }

    private String buildConfirmationMessage() {
        return "📚 **DERS KAYDI**\n\n" +
                "Yeni ders(ler) eklemek için süreci başlatalım mı?\n\n" +
                "✅ Evet - Devam et\n" +
                "❌ Hayır - İptal et";
    }

    private String buildDaySelectionMessage() {
        return "📅 **GÜN SEÇİMİ**\n\n" +
                "Hangi gün için ders eklemek istersiniz?\n\n" +
                "📌 Kullanabileceğiniz formatlar:\n" +
                "• Pazartesi, Salı, Çarşamba, Perşembe\n" +
                "• Cuma, Cumartesi, Pazar\n" +
                "• Kısa: Pzt, Sl, Çar, Per, Cm, Cmt, Paz";
    }

    private String buildFirstLessonPrompt() {
        return "📖 **1. DERS BİLGİSİ**\n\n" +
                "İlk dersinizin bilgilerini şu formatta girin:\n" +
                "**[Ders Adı] [Başlangıç]-[Bitiş]**\n\n" +
                "📝 Örnekler:\n" +
                "• Matematik 08:00-09:30\n" +
                "• Fizik Laboratuvarı 13:15-15:00\n" +
                "• İngilizce 9:00-10:00";
    }

    private String buildNextLessonPrompt(int lessonNumber, int total) {
        return String.format("📖 **%d. DERS BİLGİSİ** (%d/%d)\n\n" +
                        "Sonraki dersinizin bilgilerini girin:\n" +
                        "**[Ders Adı] [Başlangıç]-[Bitiş]**",
                lessonNumber, lessonNumber, total);
    }

    private String buildInvalidFormatMessage(int lessonNumber) {
        return String.format("❌ **HATALI FORMAT**\n\n" +
                "%d. ders için doğru formatı kullanın:\n" +
                "**[Ders Adı] [Başlangıç]-[Bitiş]**\n\n" +
                "📝 Örnek: Matematik 08:00-09:30", lessonNumber);
    }

    private String buildCompletionMessage(DayOfWeek day, int lessonCount) {
        chatStateService.setState(chatProgressService.getCurrentStudentId(), ChatState.GUN_BEKLENIYOR);

        return String.format("✅ **TAMAMLANDI!**\n\n" +
                        "%s günü için %d ders başarıyla eklendi!\n\n" +
                        "🔄 Başka bir gün için ders eklemek ister misiniz?\n" +
                        "• Gün adı yazın (örn: Salı)\n" +
                        "• 'Hayır' - İşlemi bitir\n" +
                        "• 'Programımı göster' - Mevcut programı görüntüle",
                getDayNameInTurkish(day), lessonCount);
    }

    private String showCurrentSchedule(Student student) {
        List<Course> courses = courseService.getCoursesByStudent(student.getId());

        if (courses.isEmpty()) {
            return "📋 **PROGRAM BOŞ**\n\n" +
                    "Henüz hiç ders eklememişsiniz.\n" +
                    "'ders ekle' yazarak başlayabilirsiniz! 😊";
        }

        StringBuilder schedule = new StringBuilder("📋 **DERS PROGRAMINIZ**\n\n");

        courses.stream()
                .collect(java.util.stream.Collectors.groupingBy(Course::getDay))
                .entrySet().stream()
                .sorted(java.util.Map.Entry.comparingByKey())
                .forEach(entry -> {
                    schedule.append(String.format("📅 **%s**\n", getDayNameInTurkish(entry.getKey())));
                    entry.getValue().stream()
                            .sorted((c1, c2) -> c1.getStartTime().compareTo(c2.getStartTime()))
                            .forEach(course -> {
                                schedule.append(String.format("   🕐 %s - %s: %s\n",
                                        course.getStartTime().format(DateTimeFormatter.ofPattern("HH:mm")),
                                        course.getEndTime().format(DateTimeFormatter.ofPattern("HH:mm")),
                                        course.getName()));
                            });
                    schedule.append("\n");
                });

        return schedule.toString();
    }

    private String formatCourseList(List<Course> courses) {
        return courses.stream()
                .map(c -> String.format("%s (%s-%s)",
                        c.getName(),
                        c.getStartTime().format(DateTimeFormatter.ofPattern("HH:mm")),
                        c.getEndTime().format(DateTimeFormatter.ofPattern("HH:mm"))))
                .collect(java.util.stream.Collectors.joining(", "));
    }
}