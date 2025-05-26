package bingol.campus.security.repository;

import bingol.campus.security.entity.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.Optional;

public interface UserRepository extends JpaRepository<User, Long> {
    Optional<User> findByUserNumber(String userNumber); // Kullanıcı numarasına göre kullanıcı bulma
}
