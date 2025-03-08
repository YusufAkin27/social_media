package bingol.campus.security.manager;

import bingol.campus.response.ResponseMessage;
import bingol.campus.security.dto.*;
import bingol.campus.security.entity.User;
import bingol.campus.security.exception.*;

import bingol.campus.security.repository.TokenRepository;
import bingol.campus.security.repository.UserRepository;
import bingol.campus.security.service.JwtService;
import bingol.campus.student.entity.Student;

import bingol.campus.student.repository.StudentRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.util.Optional;

@Service
@RequiredArgsConstructor
public class AuthManager implements AuthService {
    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final TokenRepository tokenRepository;
    private final StudentRepository studentRepository;

    @Override
    @Transactional
    public ResponseMessage logout(String username) throws UserNotFoundException {
        Student student = studentRepository.findByUserNumber(username).orElseThrow(UserNotFoundException::new);
        tokenRepository.deleteAllByUserId(student.getId());


        return new ResponseMessage("Çıkış başarılı", true);
    }
    @Override
    public TokenResponseDTO login(LoginRequestDTO loginRequestDTO) throws NotFoundUserException, UserDeletedException, UserNotActiveException, IncorrectPasswordException, UserRoleNotAssignedException {
        Optional<User> userOptional = userRepository.findByUserNumber(loginRequestDTO.getUsername());
        User user = userOptional.orElseThrow(NotFoundUserException::new);

        if (user instanceof Student student) {
            if (Boolean.TRUE.equals(student.getIsDeleted())) {
                throw new UserDeletedException();
            }
            if (Boolean.FALSE.equals(student.getIsActive())) {
                throw new UserNotActiveException();
            }
        }

        if (!passwordEncoder.matches(loginRequestDTO.getPassword(), user.getPassword())) {
            throw new IncorrectPasswordException();
        }

        if (user.getRoles() == null || user.getRoles().isEmpty()) {
            throw new UserRoleNotAssignedException();
        }

        String accessToken = jwtService.generateAccessToken(user, loginRequestDTO.getIpAddress(), loginRequestDTO.getDeviceInfo());
        String refreshToken = jwtService.generateRefreshToken(user, loginRequestDTO.getIpAddress(), loginRequestDTO.getDeviceInfo());

        System.out.println("giriş yapmaya çalışan kullanıcı :"+loginRequestDTO.getUsername());
        System.out.println("access token :"+accessToken);
        return new TokenResponseDTO(accessToken, refreshToken);
    }


    @Override
    public ResponseEntity<?> updateAccessToken(UpdateAccessTokenRequestDTO updateAccessTokenRequestDTO) {
        try {
            if (!jwtService.validateRefreshToken(updateAccessTokenRequestDTO.getRefreshToken())) {
                throw new InvalidRefreshTokenException();
            }

            String userNumber = jwtService.getRefreshTokenClaims(updateAccessTokenRequestDTO.getRefreshToken()).getSubject();
            User user = userRepository.findByUserNumber(userNumber)
                    .orElseThrow(UserNotFoundException::new);

            String ipAddress = updateAccessTokenRequestDTO.getIpAddress();
            String deviceInfo = updateAccessTokenRequestDTO.getDeviceInfo();
            String newAccessToken = jwtService.generateAccessToken(user, ipAddress, deviceInfo);

            return ResponseEntity.ok(new AccessTokenResponse(newAccessToken));
        } catch (TokenNotFoundException e) {
            return ResponseEntity.status(HttpStatus.BAD_REQUEST).body("Token bulunamadı: " + e.getMessage());
        } catch (InvalidRefreshTokenException e) {
            return ResponseEntity.status(HttpStatus.FORBIDDEN).body("Refresh token geçersiz: " + e.getMessage());
        } catch (UserNotFoundException e) {
            return ResponseEntity.status(HttpStatus.NOT_FOUND).body("Kullanıcı hatası: " + e.getMessage());
        } catch (Exception e) {
            return ResponseEntity.status(HttpStatus.INTERNAL_SERVER_ERROR).body("Bir hata meydana geldi: " + e.getMessage());
        }
    }




}
