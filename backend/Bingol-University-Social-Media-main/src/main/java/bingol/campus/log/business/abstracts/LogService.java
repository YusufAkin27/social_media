package bingol.campus.log.business.abstracts;

import bingol.campus.log.core.exception.LogNotFoundException;
import bingol.campus.log.core.request.CreateLogRequest;
import bingol.campus.log.core.response.LogsDTO;
import bingol.campus.log.entity.Log;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.student.entity.Student;
import bingol.campus.student.exceptions.StudentDeletedException;
import bingol.campus.student.exceptions.StudentNotActiveException;
import bingol.campus.student.exceptions.StudentNotFoundException;

import java.util.List;
import java.util.UUID;

public interface LogService {
    ResponseMessage addLog(CreateLogRequest createLogRequest) throws StudentNotFoundException, StudentNotActiveException, StudentDeletedException;

    ResponseMessage deleteLog(String username, UUID logId) throws StudentNotFoundException, LogNotFoundException;

    DataResponseMessage<List<LogsDTO>> getLogs(String username) throws StudentNotFoundException;
    List<Log> getActiveLogs(Student student);
}
