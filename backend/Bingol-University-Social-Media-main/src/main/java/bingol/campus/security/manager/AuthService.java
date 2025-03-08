package bingol.campus.security.manager;



import bingol.campus.response.ResponseMessage;
import bingol.campus.security.dto.LoginRequestDTO;
import bingol.campus.security.dto.TokenResponseDTO;
import bingol.campus.security.dto.UpdateAccessTokenRequestDTO;
import bingol.campus.security.exception.*;
import org.springframework.http.ResponseEntity;

public interface AuthService {


    TokenResponseDTO login(LoginRequestDTO loginRequestDTO) throws NotFoundUserException, IncorrectPasswordException, UserDeletedException, UserNotActiveException, UserRoleNotAssignedException;

    ResponseEntity<?> updateAccessToken(UpdateAccessTokenRequestDTO updateAccessTokenRequestDTO) throws TokenIsExpiredException, TokenNotFoundException;

    ResponseMessage logout(String username) throws UserNotFoundException;
}
