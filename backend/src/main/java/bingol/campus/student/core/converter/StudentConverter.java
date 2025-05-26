package bingol.campus.student.core.converter;

import bingol.campus.student.core.response.*;
import bingol.campus.student.core.request.CreateStudentRequest;
import bingol.campus.student.entity.Student;
import bingol.campus.student.exceptions.StudentNotFoundException;

public interface StudentConverter {
    Student createToStudent(CreateStudentRequest createStudentRequest);
    StudentDTO toDto(Student student);
    PublicAccountDetails publicAccountDto(Student student);
    PrivateAccountDetails privateAccountDto(Student student);
    SearchAccountDTO toSearchAccountDTO(Student student);
}
