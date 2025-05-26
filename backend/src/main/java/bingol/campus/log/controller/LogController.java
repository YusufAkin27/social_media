package bingol.campus.log.controller;

import bingol.campus.log.business.abstracts.LogService;
import bingol.campus.log.core.exception.LogNotFoundException;
import bingol.campus.log.core.request.CreateLogRequest;
import bingol.campus.log.core.response.LogsDTO;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.student.exceptions.StudentDeletedException;
import bingol.campus.student.exceptions.StudentNotActiveException;
import bingol.campus.student.exceptions.StudentNotFoundException;
import lombok.RequiredArgsConstructor;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/v1/api/logs")
@RequiredArgsConstructor
public class LogController {
    private final LogService logService;


    @DeleteMapping("/{logId}")
    public ResponseMessage deleteLog(@AuthenticationPrincipal UserDetails userDetails,
                                    @PathVariable UUID logId) throws StudentNotFoundException, LogNotFoundException {
        return logService.deleteLog(userDetails.getUsername(),logId);
    }

    @GetMapping("/logs")
    public DataResponseMessage<List<LogsDTO>>getLogs(@AuthenticationPrincipal UserDetails userDetails) throws StudentNotFoundException {
        return logService.getLogs(userDetails.getUsername());
    }
    @PostMapping("/add")
    public ResponseMessage addLog(@RequestBody CreateLogRequest createLogRequest) throws StudentNotFoundException, StudentDeletedException, StudentNotActiveException {
        return logService.addLog(createLogRequest);
    }
}
