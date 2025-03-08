package bingol.campus.student.rules;

import bingol.campus.student.core.request.CreateStudentRequest;
import bingol.campus.student.entity.Student;
import bingol.campus.student.entity.enums.Department;
import bingol.campus.student.entity.enums.Faculty;
import bingol.campus.student.exceptions.*;
import bingol.campus.student.repository.StudentRepository;

import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Component;

import java.util.List;

@Component
@RequiredArgsConstructor
public class StudentRules {

    private final StudentRepository studentRepository;


    public void baseControl(Student student) throws StudentNotActiveException, StudentDeletedException {
        if (!student.getIsActive()) {
            throw new StudentNotActiveException();
        }
        if (student.getIsDeleted()) {
            throw new StudentDeletedException();
        }
    }


    public void validateUsername(String username) throws DuplicateUsernameException, InvalidUsernameException {
        // Kullanıcı adı null ise veya 7 karakterden kısa ise, ya da belirtilen desenle eşleşmiyorsa InvalidUsernameException fırlat.
        if (username == null  || !username.matches("^[a-zA-ZçğıöşüÇĞİÖŞÜ0-9._-]{5,20}$")) {
            throw new InvalidUsernameException();
        }

        // Eğer kullanıcı adı zaten mevcutsa, DuplicateUsernameException fırlat.
        if (studentRepository.existsByUserNumber(username)) {
            throw new DuplicateUsernameException();
        }
    }



    public void validateMobilePhone(String mobilePhone) throws InvalidMobilePhoneException, DuplicateMobilePhoneException {
        if (mobilePhone == null || (mobilePhone = mobilePhone.replaceAll("\\s", "")).length() != 10 || !mobilePhone.matches("\\d{10}")) {
            throw new InvalidMobilePhoneException();
        }
        if (studentRepository.existsByMobilePhone(mobilePhone)) {
            throw new DuplicateMobilePhoneException();
        }
    }


    // Email kontrolü (format ve benzersizlik)
    public void validateEmail(String email) throws InvalidEmailException, DuplicateEmailException {
        // E-posta doğrulama: Genel format kontrolü ve bingol.edu.tr ile bitiş kontrolü
        //if (email == null || !email.matches("^\\d{9}@bingol\\.edu\\.tr$")) {
          //  throw new InvalidEmailException();
        //}
        // Benzersizlik kontrolü
        if (studentRepository.existsByEmail(email)) {
            throw new DuplicateEmailException();
        }
    }
    public void validateFacultyAndDepartment(Faculty faculty, Department department) throws ValidateDepartmentException {
        List<Department> validDepartments = faculty.getDepartments();

        if (!validDepartments.contains(department)) {
            throw new ValidateDepartmentException(faculty,department,validDepartments);
        }
    }

    public void validatePassword(String password) throws IllegalPasswordException {
        if (password == null || password.strip().length() < 6) throw new IllegalPasswordException();
    }


    // Diğer kontroller (zorunlu alanlar boş olmamalı)
    public void validateRequiredFields(CreateStudentRequest request) throws MissingRequiredFieldException {
        if (request.getFirstName() == null || request.getFirstName().isEmpty()) {
            throw new MissingRequiredFieldException();
        }
        if (request.getLastName() == null || request.getLastName().isEmpty()) {
            throw new MissingRequiredFieldException();
        }
        if (request.getDepartment() == null) {
            throw new MissingRequiredFieldException();
        }
        if (request.getFaculty() == null) {
            throw new MissingRequiredFieldException();
        }
        if (request.getGrade() == null) {
            throw new MissingRequiredFieldException();
        }
        if (request.getBirthDate() == null) {
            throw new MissingRequiredFieldException();
        }
    }

    // Tüm kontrolleri çağıran yöntem
    public void validate(CreateStudentRequest request) throws DuplicateUsernameException, InvalidMobilePhoneException, DuplicateMobilePhoneException, InvalidEmailException, DuplicateEmailException, MissingRequiredFieldException, InvalidUsernameException, IllegalPasswordException, ValidateDepartmentException {
        validateUsername(request.getUsername());
        validatePassword(request.getPassword());
        validateFacultyAndDepartment(request.getFaculty(),request.getDepartment());
        validateMobilePhone(request.getMobilePhone());
        validateEmail(request.getEmail());
        validateRequiredFields(request);
    }
}
