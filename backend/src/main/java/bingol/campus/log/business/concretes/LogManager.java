package bingol.campus.log.business.concretes;

import bingol.campus.log.business.abstracts.LogService;
import bingol.campus.log.core.exception.LogNotFoundException;
import bingol.campus.log.core.request.CreateLogRequest;
import bingol.campus.log.core.response.LogsDTO;
import bingol.campus.log.entity.Log;
import bingol.campus.log.repository.LogRepository;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.student.entity.Student;
import bingol.campus.student.exceptions.StudentDeletedException;
import bingol.campus.student.exceptions.StudentNotActiveException;
import bingol.campus.student.exceptions.StudentNotFoundException;
import bingol.campus.student.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.scheduling.annotation.Scheduled;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class LogManager implements LogService {
    private final LogRepository logRepository;
    private final StudentRepository studentRepository;

    @Override
    public List<Log> getActiveLogs(Student student) {
        LocalDateTime oneMonthAgo = LocalDateTime.now().minusMonths(1);
        return logRepository.findByStudentAndSendTimeAfterAndIsActiveTrue(student, oneMonthAgo);
    }

    @Scheduled(cron = "0 0 0 * * ?") // Her gece 00:00'da çalışır
    public void deleteInactiveLogs() {
        LocalDateTime oneMonthAgo = LocalDateTime.now().minusMonths(1);
        logRepository.deleteOldLogs(oneMonthAgo);
    }

    @Override
    @Transactional
    public ResponseMessage addLog(CreateLogRequest createLogRequest) throws StudentNotFoundException, StudentNotActiveException, StudentDeletedException {
        Student student = studentRepository.findById(createLogRequest.getStudentId()).orElseThrow(StudentNotFoundException::new);

        if (!student.getIsActive()) {
            throw new StudentNotActiveException();
        }
        if (student.getIsDeleted()) {
            throw new StudentDeletedException();
        }
        Log log = new Log();
        log.setActive(true);
        log.setStudent(student);
        log.setMessage(createLogRequest.getMessage());
        log.setSendTime(LocalDateTime.now());
        student.getLogs().add(log);
        studentRepository.save(student);
        logRepository.save(log);
        return new ResponseMessage("log gönderildi", true);

    }

    @Override
    @Transactional
    public ResponseMessage deleteLog(String username, UUID logId) throws StudentNotFoundException, LogNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        Log log = getActiveLogs(student).stream().filter(l -> l.getId().equals(logId)).findFirst().orElseThrow(LogNotFoundException::new);
        logRepository.delete(log);
        return new ResponseMessage("log kaldırıldı", true);
    }

    @Override
    public DataResponseMessage<List<LogsDTO>> getLogs(String username) throws StudentNotFoundException {
        Student student = studentRepository.getByUserNumber(username);
        List<LogsDTO> logsDTOS = getActiveLogs(student).stream().map(this::convert).toList();
        return new DataResponseMessage<>("loglar", true, logsDTOS);
    }

    public LogsDTO convert(Log log) {
        return LogsDTO.builder()
                .logId(log.getId())
                .message(log.getMessage())
                .sentAt(log.getSendTime())
                .build();
    }
}
