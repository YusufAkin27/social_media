package bingol.campus.admin;

import bingol.campus.admin.request.CreateAdminRequest;

import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.security.entity.Role;
import bingol.campus.security.entity.User;
import bingol.campus.security.exception.UserNotFoundException;
import bingol.campus.security.repository.UserRepository;
import bingol.campus.student.business.abstracts.StudentService;
import bingol.campus.student.core.response.StudentDTO;
import bingol.campus.student.core.response.StudentStatistics;
import bingol.campus.student.entity.enums.Department;
import bingol.campus.student.entity.enums.Faculty;
import bingol.campus.student.entity.enums.Grade;
import bingol.campus.student.exceptions.*;

import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;
import java.util.Set;

@RestController
@RequestMapping("/v1/api/admin")
@RequiredArgsConstructor
public class AdminController {

    private final StudentService studentService;
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;



    @PostMapping("/register")
    public ResponseMessage register(@RequestBody CreateAdminRequest createAdminRequest) {
        User user = new User();
        user.setUserNumber(createAdminRequest.getUsername());
        user.setPassword(passwordEncoder.encode(createAdminRequest.getPassword()));
        user.setRoles(Set.of(Role.ADMIN));
        userRepository.save(user);
        return new ResponseMessage("admin kaydedildi", true);

    }

    // Silinmiş öğrencileri listeleme
    @GetMapping("/deleted")
    public DataResponseMessage<List<StudentDTO>> getDeletedStudents(@AuthenticationPrincipal UserDetails userDetails) throws UserNotFoundException, UnauthorizedException {
        // Silinmiş öğrencileri listeler
        return studentService.getDeletedStudents(userDetails.getUsername());
    }

    // Silinmiş öğrenciyi geri yükleme
    @PutMapping("/{studentId}/restore")
    public ResponseMessage restoreDeletedStudent(@AuthenticationPrincipal UserDetails userDetails,
                                                 @RequestParam Long studentId) throws UserNotFoundException, InvalidOperationException, UnauthorizedException, StudentNotFoundException {
        // Silinmiş bir öğrenciyi geri yükler
        return studentService.restoreDeletedStudent(userDetails.getUsername(), studentId);
    }

    // Akademik bilgileri güncelleme
    @PutMapping("/{studentId}/academic-info")
    public ResponseMessage updateAcademicInfo(@AuthenticationPrincipal UserDetails userDetails,
                                              @RequestParam Department department,
                                              @RequestParam Faculty faculty) throws InvalidDepartmentException, StudentNotFoundException, InvalidFacultyException, StudentNotActiveException {
        return studentService.updateAcademicInfo(userDetails.getUsername(), department, faculty);
    }

    // Öğrenci istatistiklerini döner
    @GetMapping("/statistics")
    public DataResponseMessage<StudentStatistics> getStudentStatistics(@AuthenticationPrincipal UserDetails userDetails) throws UserNotFoundException, UnauthorizedException {
        return studentService.getStudentStatistics(userDetails.getUsername());
    }

    // Doğum tarihi ve sınıfa göre filtreleme
    @GetMapping("/filter")
    public DataResponseMessage<List<StudentDTO>> filterStudents(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) LocalDate birthDate,
            @RequestParam(required = false) Grade grade) throws UserNotFoundException, UnauthorizedException {
        return studentService.filterStudents(userDetails.getUsername(), birthDate, grade);
    }

    // Bölüm veya fakülteye göre öğrenci sayısını döner
    @GetMapping("/count")
    public DataResponseMessage countStudentsByDepartmentOrFaculty(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(required = false) Department department,
            @RequestParam(required = false) Faculty faculty) throws UserNotFoundException, UnauthorizedException {
        return studentService.countStudentsByDepartmentOrFaculty(userDetails.getUsername(), department, faculty);
    }

    // Tüm öğrencileri listeleme (Sayfalandırma ile)
    @GetMapping("/all")
    public DataResponseMessage<List<StudentDTO>> getAllStudents(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam(defaultValue = "0") int page,
            @RequestParam(defaultValue = "10") int size) throws UserNotFoundException, UnauthorizedException {
        return studentService.getAllStudents(userDetails.getUsername(), page, size);
    }

    // Öğrenci durumu güncelleme
    @PutMapping("/{studentId}/status")
    public ResponseMessage updateStudentStatus(
            @AuthenticationPrincipal UserDetails userDetails,
            @RequestParam Boolean isActive) throws StudentNotFoundException, StudentStatusAlreadySetException {
        return studentService.updateStudentStatus(userDetails.getUsername(), isActive);
    }
    @PostMapping("/{studentId}/moderator")
    public ResponseMessage addModerator(@AuthenticationPrincipal UserDetails userDetails,
                                        @PathVariable Long studentId) throws UserNotFoundException, UnauthorizedException, StudentNotFoundException {
        return studentService.addModerator(userDetails.getUsername(),studentId);
    }
    @DeleteMapping("/{studentId}/moderator")
    public ResponseMessage removeModerator(@AuthenticationPrincipal UserDetails userDetails,
                                           @PathVariable Long studentId) throws UnauthorizedException, StudentNotFoundException {
        return studentService.removeModerator(userDetails.getUsername(), studentId);
    }
    @GetMapping("/moderators")
    public DataResponseMessage<List<StudentDTO>> getModerators(@AuthenticationPrincipal UserDetails userDetails) throws UnauthorizedException, StudentNotFoundException {
        return studentService.getModerators(userDetails.getUsername());
    }

}
