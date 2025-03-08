package bingol.campus.chat.repository;

import bingol.campus.chat.entity.PrivateChat;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.UUID;

public interface PrivateChatRepository extends JpaRepository<PrivateChat, UUID> {
}
