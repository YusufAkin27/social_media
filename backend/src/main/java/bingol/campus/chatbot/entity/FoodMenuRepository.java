package bingol.campus.chatbot.entity;

import org.springframework.data.jpa.repository.JpaRepository;

import java.time.LocalDate;
import java.util.Optional;

public interface FoodMenuRepository extends JpaRepository<FoodMenu, Long> {
    Optional<FoodMenu> findByTarih(LocalDate tarih);
}
