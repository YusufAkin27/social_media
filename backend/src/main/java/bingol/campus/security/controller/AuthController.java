package bingol.campus.security.controller;


import bingol.campus.response.ResponseMessage;
import bingol.campus.security.dto.LoginRequestDTO;
import bingol.campus.security.dto.TokenResponseDTO;
import bingol.campus.security.dto.UpdateAccessTokenRequestDTO;
import bingol.campus.security.exception.*;
import bingol.campus.security.manager.AuthService;
import lombok.RequiredArgsConstructor;

import org.springframework.http.ResponseEntity;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.security.core.userdetails.UserDetails;
import org.springframework.web.bind.annotation.*;


@RestController
@RequestMapping("/v1/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;


    @PostMapping("/login")
    public TokenResponseDTO login(@RequestBody LoginRequestDTO loginRequestDTO) throws UserNotActiveException, UserRoleNotAssignedException, UserDeletedException, NotFoundUserException, IncorrectPasswordException {
        return authService.login(loginRequestDTO);
    }
    @PostMapping("/refresh")
    public ResponseEntity<?> updateAccessToken(@RequestBody UpdateAccessTokenRequestDTO updateAccessTokenRequestDTO) throws TokenIsExpiredException, TokenNotFoundException {
        return authService.updateAccessToken(updateAccessTokenRequestDTO);
    }
    @PostMapping("logout")
    public ResponseMessage logout(@AuthenticationPrincipal UserDetails userDetails) throws UserNotFoundException {
      return authService.logout(userDetails.getUsername());
    }

}
