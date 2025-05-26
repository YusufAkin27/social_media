package bingol.campus.blockRelation.business.abstracts;

import bingol.campus.blockRelation.core.exceptions.AlreadyBlockUserException;
import bingol.campus.blockRelation.core.exceptions.BlockUserNotFoundException;
import bingol.campus.blockRelation.core.response.BlockUserDTO;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.student.exceptions.StudentDeletedException;
import bingol.campus.student.exceptions.StudentNotActiveException;
import bingol.campus.student.exceptions.StudentNotFoundException;
import org.springframework.data.domain.Pageable;

import java.time.LocalDate;
import java.util.List;

public interface BlockRelationService {

    ResponseMessage unblock(String username, Long userId) throws BlockUserNotFoundException, StudentNotFoundException;

    ResponseMessage checkBlockStatus(String username, Long userId) throws StudentNotFoundException;

    DataResponseMessage<LocalDate> getBlockHistory(String username, Long userId) throws BlockUserNotFoundException, StudentNotFoundException;

    DataResponseMessage<BlockUserDTO> getUserDetails(String username, Long userId) throws BlockUserNotFoundException, StudentNotFoundException;

    DataResponseMessage getBlockCount(String username) throws StudentNotFoundException;

    ResponseMessage addWithReason(String username, Long userId) throws BlockUserNotFoundException, AlreadyBlockUserException, StudentNotFoundException, StudentDeletedException, StudentNotActiveException;

    DataResponseMessage<List<BlockUserDTO>>getBlockedUsers(String username, Pageable pageable) throws StudentNotFoundException;
}
