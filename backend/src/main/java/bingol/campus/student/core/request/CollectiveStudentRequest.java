package bingol.campus.student.core.request;

import lombok.Data;

import java.util.List;

@Data
public class CollectiveStudentRequest {
    private List<CreateStudentRequest> createStudentRequestList;
}
