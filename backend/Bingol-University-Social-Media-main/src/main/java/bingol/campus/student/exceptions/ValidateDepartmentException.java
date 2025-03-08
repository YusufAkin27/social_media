package bingol.campus.student.exceptions;

import bingol.campus.security.exception.BusinessException;
import bingol.campus.student.entity.enums.Department;
import bingol.campus.student.entity.enums.Faculty;

import java.util.List;

public class ValidateDepartmentException extends BusinessException {

    public ValidateDepartmentException(Faculty faculty, Department department, List<Department> validDepartments) {
        super("Seçilen departman bu fakülteye ait değil: "
                + department + " (Geçerli Bölümler: " + validDepartments + ")");
    }
}
