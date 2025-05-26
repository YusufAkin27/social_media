// CourseService - Ders yönetimi için
package bingol.campus.chatbot.manager;

import bingol.campus.chatbot.entity.Course;
import bingol.campus.chatbot.entity.CourseRepository;
import bingol.campus.student.entity.Student;
import bingol.campus.student.repository.StudentRepository;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.DayOfWeek;
import java.time.LocalTime;
import java.util.List;
import java.util.Optional;

@Service
@Transactional
public class CourseService {

    @Autowired
    private CourseRepository courseRepository;

    @Autowired
    private StudentRepository studentRepository;

    /**
     * Belirli bir öğrencinin belirli bir gündeki derslerini getirir
     */
    public List<Course> getCoursesByStudentAndDay(Long studentId, DayOfWeek dayOfWeek) {
        return courseRepository.findByStudentsIdAndDay(studentId, dayOfWeek);
    }

    /**
     * Yeni ders saati mevcut derslerle çakışıyor mu kontrol eder
     */
    public boolean hasTimeConflict(Long studentId, DayOfWeek day, LocalTime startTime, LocalTime endTime) {
        List<Course> existingCourses = getCoursesByStudentAndDay(studentId, day);

        return existingCourses.stream().anyMatch(course -> {
            LocalTime existingStart = course.getStartTime();
            LocalTime existingEnd = course.getEndTime();

            // Çakışma kontrolü:
            // 1. Yeni ders mevcut dersin başlangıcından önce başlayıp sonunda bitmiyorsa
            // 2. Yeni ders mevcut dersin içinde başlamıyorsa
            // 3. Yeni ders mevcut dersi tamamen kapsamıyorsa
            return !(endTime.isBefore(existingStart) || endTime.equals(existingStart) ||
                    startTime.isAfter(existingEnd) || startTime.equals(existingEnd));
        });
    }

    /**
     * Yeni bir ders kaydeder
     */
    public void saveCourse(Long studentId, DayOfWeek day, String courseName, LocalTime startTime, LocalTime endTime) {
        Optional<Student> studentOpt = studentRepository.findById(studentId);

        if (studentOpt.isPresent()) {
            Student student = studentOpt.get();

            // Yeni ders oluştur
            Course newCourse = new Course();
            newCourse.setName(courseName.trim());
            newCourse.setDay(day);
            newCourse.setStartTime(startTime);
            newCourse.setEndTime(endTime);

            // Dersi kaydet
            Course savedCourse = courseRepository.save(newCourse);

            // Öğrenci ile dersi ilişkilendir
            student.getCourses().add(savedCourse);
            savedCourse.getStudents().add(student);

            studentRepository.save(student);
        } else {
            throw new RuntimeException("Öğrenci bulunamadı: " + studentId);
        }
    }

    /**
     * Belirli bir öğrencinin tüm derslerini getirir
     */
    public List<Course> getCoursesByStudent(Long studentId) {
        return courseRepository.findByStudentsId(studentId);
    }

    /**
     * Öğrencinin belirli bir gündeki ders sayısını getirir
     */
    public int getCourseCountByStudentAndDay(Long studentId, DayOfWeek dayOfWeek) {
        return getCoursesByStudentAndDay(studentId, dayOfWeek).size();
    }

    /**
     * Öğrencinin toplam ders sayısını getirir
     */
    public int getTotalCourseCountByStudent(Long studentId) {
        return getCoursesByStudent(studentId).size();
    }

    /**
     * Belirli bir dersi siler
     */
    public boolean deleteCourse(Long courseId, Long studentId) {
        Optional<Course> courseOpt = courseRepository.findById(courseId);
        Optional<Student> studentOpt = studentRepository.findById(studentId);

        if (courseOpt.isPresent() && studentOpt.isPresent()) {
            Course course = courseOpt.get();
            Student student = studentOpt.get();

            // İlişkiyi kaldır
            student.getCourses().remove(course);
            course.getStudents().remove(student);

            // Eğer başka öğrenci yoksa dersi tamamen sil
            if (course.getStudents().isEmpty()) {
                courseRepository.delete(course);
            }

            studentRepository.save(student);
            return true;
        }

        return false;
    }

    /**
     * Öğrencinin belirli bir günündeki en erken ve en geç ders saatlerini getirir
     */
    public TimeRange getDayTimeRange(Long studentId, DayOfWeek dayOfWeek) {
        List<Course> courses = getCoursesByStudentAndDay(studentId, dayOfWeek);

        if (courses.isEmpty()) {
            return null;
        }

        LocalTime earliest = courses.stream()
                .map(Course::getStartTime)
                .min(LocalTime::compareTo)
                .orElse(null);

        LocalTime latest = courses.stream()
                .map(Course::getEndTime)
                .max(LocalTime::compareTo)
                .orElse(null);

        return new TimeRange(earliest, latest);
    }

    /**
     * Öğrencinin haftalık ders yoğunluğunu hesaplar
     */
    public WeeklyScheduleStats getWeeklyStats(Long studentId) {
        List<Course> allCourses = getCoursesByStudent(studentId);

        int totalCourses = allCourses.size();
        long totalHours = allCourses.stream()
                .mapToLong(course -> java.time.Duration.between(
                        course.getStartTime(), course.getEndTime()).toMinutes())
                .sum();

        // En yoğun günü bul
        DayOfWeek busiestDay = null;
        int maxCoursesInDay = 0;

        for (DayOfWeek day : DayOfWeek.values()) {
            int courseCount = getCourseCountByStudentAndDay(studentId, day);
            if (courseCount > maxCoursesInDay) {
                maxCoursesInDay = courseCount;
                busiestDay = day;
            }
        }

        return new WeeklyScheduleStats(totalCourses, totalHours / 60.0, busiestDay, maxCoursesInDay);
    }

    // Yardımcı sınıflar
    public static class TimeRange {
        private final LocalTime startTime;
        private final LocalTime endTime;

        public TimeRange(LocalTime startTime, LocalTime endTime) {
            this.startTime = startTime;
            this.endTime = endTime;
        }

        public LocalTime getStartTime() { return startTime; }
        public LocalTime getEndTime() { return endTime; }
    }

    public static class WeeklyScheduleStats {
        private final int totalCourses;
        private final double totalHours;
        private final DayOfWeek busiestDay;
        private final int maxCoursesInDay;

        public WeeklyScheduleStats(int totalCourses, double totalHours,
                                   DayOfWeek busiestDay, int maxCoursesInDay) {
            this.totalCourses = totalCourses;
            this.totalHours = totalHours;
            this.busiestDay = busiestDay;
            this.maxCoursesInDay = maxCoursesInDay;
        }

        public int getTotalCourses() { return totalCourses; }
        public double getTotalHours() { return totalHours; }
        public DayOfWeek getBusiestDay() { return busiestDay; }
        public int getMaxCoursesInDay() { return maxCoursesInDay; }
    }
}

