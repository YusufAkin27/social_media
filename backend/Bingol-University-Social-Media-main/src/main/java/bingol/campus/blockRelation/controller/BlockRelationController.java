package bingol.campus.blockRelation.controller;

import bingol.campus.blockRelation.business.abstracts.BlockRelationService;
import bingol.campus.blockRelation.core.exceptions.AlreadyBlockUserException;
import bingol.campus.blockRelation.core.exceptions.BlockUserNotFoundException;
import bingol.campus.blockRelation.core.response.BlockUserDTO;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.security.entity.User;
import bingol.campus.student.exceptions.StudentDeletedException;
import bingol.campus.student.exceptions.StudentNotActiveException;
import bingol.campus.student.exceptions.StudentNotFoundException;
import lombok.RequiredArgsConstructor;

import org.springframework.data.domain.Pageable;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;

import java.time.LocalDate;
import java.util.List;

@RestController
@RequestMapping("/v1/api/block-relations")
@RequiredArgsConstructor
public class BlockRelationController {

    private final BlockRelationService blockRelationService;

    @GetMapping("/blocked")
    public DataResponseMessage<List<BlockUserDTO>> getBlockedUsers(@AuthenticationPrincipal UserDetails userDetails, Pageable pageable) throws StudentNotFoundException {
        return blockRelationService.getBlockedUsers(userDetails.getUsername(), pageable);
    }


    @DeleteMapping("/unblock/{userId}")
    public ResponseMessage unblock(@AuthenticationPrincipal UserDetails userDetails, @PathVariable Long userId) throws BlockUserNotFoundException, StudentNotFoundException {
        return blockRelationService.unblock(userDetails.getUsername(), userId);
    }

    @GetMapping("/is-blocked/{userId}")
    public ResponseMessage checkBlockStatus(@AuthenticationPrincipal UserDetails userDetails, @PathVariable Long userId) throws StudentNotFoundException {
        return blockRelationService.checkBlockStatus(userDetails.getUsername(), userId);
    }
    @GetMapping("/block-history/{userId}")
    public DataResponseMessage<LocalDate> getBlockHistory(@AuthenticationPrincipal UserDetails userDetails, @PathVariable Long userId) throws BlockUserNotFoundException, StudentNotFoundException {
        return blockRelationService.getBlockHistory(userDetails.getUsername(),userId);
    }
    @GetMapping("/block-count")
    public DataResponseMessage getBlockCount(@AuthenticationPrincipal UserDetails userDetails) throws StudentNotFoundException {
        return blockRelationService.getBlockCount(userDetails.getUsername());
    }

    @GetMapping("/user/{userId}")
    public DataResponseMessage<BlockUserDTO> getUserDetails(@AuthenticationPrincipal UserDetails userDetails, @PathVariable Long userId) throws BlockUserNotFoundException, StudentNotFoundException {
        return blockRelationService.getUserDetails(userDetails.getUsername(), userId);
    }


    @PostMapping("/block/{userId}")
    public ResponseMessage addWithReason(@AuthenticationPrincipal UserDetails userDetails,
                                         @PathVariable Long userId) throws BlockUserNotFoundException, AlreadyBlockUserException, StudentNotFoundException, StudentDeletedException, StudentNotActiveException {
        return blockRelationService.addWithReason(userDetails.getUsername(), userId);
    }

}
