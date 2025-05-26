package bingol.campus.student.business.abstracts;



import bingol.campus.friendRequest.core.exceptions.BlockedByUserException;
import bingol.campus.friendRequest.core.exceptions.UserBlockedException;
import bingol.campus.post.core.response.PostDTO;
import bingol.campus.response.DataResponseMessage;
import bingol.campus.response.ResponseMessage;
import bingol.campus.security.exception.UserNotFoundException;
import bingol.campus.student.core.request.SuggestUserRequest;
import bingol.campus.student.core.response.*;
import bingol.campus.student.core.request.CreateStudentRequest;
import bingol.campus.student.core.request.UpdateStudentProfileRequest;
import bingol.campus.student.entity.enums.Department;
import bingol.campus.student.entity.enums.Faculty;
import bingol.campus.student.entity.enums.Grade;
import bingol.campus.student.exceptions.*;
import org.springframework.web.multipart.MultipartFile;

import java.io.IOException;
import java.time.LocalDate;
import java.util.List;

public interface StudentService {
    ResponseMessage signUp(CreateStudentRequest createStudentRequest) throws DuplicateTcIdentityNumberException, DuplicateUsernameException, MissingRequiredFieldException, DuplicateMobilePhoneException, DuplicateEmailException, InvalidMobilePhoneException, InvalidSchoolNumberException, InvalidTcIdentityNumberException, InvalidEmailException, InvalidUsernameException, IllegalPasswordException, ValidateDepartmentException;

    DataResponseMessage<StudentDTO> getStudentProfile(String username) throws StudentNotFoundException;

    ResponseMessage updateStudentProfile(String username, UpdateStudentProfileRequest updateRequest) throws StudentNotFoundException, StudentDeletedException, StudentNotActiveException, DuplicateUsernameException, DuplicateMobilePhoneException, InvalidMobilePhoneException, InvalidUsernameException;

    ResponseMessage uploadProfilePhoto(String username, MultipartFile file) throws StudentNotFoundException, IOException, StudentDeletedException, StudentNotActiveException;


    ResponseMessage deleteStudent(String username) throws StudentNotFoundException, StudentAlreadyIsActiveException;

    ResponseMessage updatePassword(String username, String newPassword) throws StudentNotFoundException, StudentInactiveException, SamePasswordException, StudentDeletedException, StudentNotActiveException, IllegalPasswordException;

    ResponseMessage updateStudentStatus(String username, Boolean isActive) throws StudentNotFoundException, StudentStatusAlreadySetException;

    DataResponseMessage<List<StudentDTO>> getAllStudents(String username,int page, int size) throws UnauthorizedException, UserNotFoundException;

    DataResponseMessage countStudentsByDepartmentOrFaculty(String username, Department department, Faculty faculty) throws UserNotFoundException, UnauthorizedException;

    ResponseMessage deleteProfilePhoto(String username) throws StudentNotFoundException;

    DataResponseMessage<List<StudentDTO>> filterStudents(String username,LocalDate birthDate, Grade grade) throws UserNotFoundException, UnauthorizedException;

    DataResponseMessage<List<StudentDTO>> getDeletedStudents(String username) throws UserNotFoundException, UnauthorizedException;

    ResponseMessage restoreDeletedStudent(String username,Long studentId) throws InvalidOperationException, StudentNotFoundException, UnauthorizedException, UserNotFoundException;

    ResponseMessage updateAcademicInfo(String username, Department department, Faculty faculty) throws StudentNotFoundException, StudentNotActiveException, InvalidDepartmentException, InvalidFacultyException;

    DataResponseMessage<StudentStatistics> getStudentStatistics(String username) throws UserNotFoundException, UnauthorizedException;

    ResponseMessage changePrivate(String username, boolean isPrivate) throws StudentNotFoundException, ProfileStatusAlreadySetException, StudentDeletedException, StudentNotActiveException;

    DataResponseMessage<List<SearchAccountDTO>> search(String username, String query, int page) throws StudentNotFoundException;


    DataResponseMessage<List<PublicAccountDetails>> getStudentsByDepartment(String username, Department department, int page) throws StudentNotFoundException;

    DataResponseMessage<List<PublicAccountDetails>> getStudentsByFaculty(String username, Faculty faculty, int page) throws StudentNotFoundException;

    DataResponseMessage<List<PublicAccountDetails>> getStudentsByGrade(String username, Grade grade, int page) throws StudentNotFoundException;

    DataResponseMessage<List<BestPopularityAccount>> getBestPopularity(String username);

    DataResponseMessage<?> accountDetails(String username, Long userId) throws StudentNotFoundException, BlockedByUserException, UserBlockedException;


    DataResponseMessage<List<PostDTO>> getHomePosts(String username, int page) throws StudentNotFoundException;

    DataResponseMessage<List<HomeStoryDTO>> getHomeStories(String username, int page) throws StudentNotFoundException;

    ResponseMessage updateFcmToken(String username, String fcmToken) throws StudentNotFoundException;

    ResponseMessage forgotPassword(String username) throws StudentNotFoundException;

    ResponseMessage resetPassword(String token, String newPassword);

    ResponseMessage active(String token);

    DataResponseMessage<List<SuggestUserRequest>> getSuggestedConnections(String username) throws StudentNotFoundException;

    ResponseMessage addModerator(String username, Long studentId) throws UnauthorizedException, StudentNotFoundException, UserNotFoundException;

    ResponseMessage removeModerator(String username, Long studentId) throws StudentNotFoundException, UnauthorizedException;

    DataResponseMessage<List<StudentDTO>> getModerators(String username) throws StudentNotFoundException, UnauthorizedException;

    StudentDTO find(String username, String username1) throws StudentNotFoundException;

}
