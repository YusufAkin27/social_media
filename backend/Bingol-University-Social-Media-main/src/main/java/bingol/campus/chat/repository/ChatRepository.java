package bingol.campus.chat.repository;

import bingol.campus.chat.entity.Chat;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface ChatRepository extends JpaRepository<Chat, UUID> {
}
