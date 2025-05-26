package bingol.campus.chat.config;

import org.springframework.context.annotation.Configuration;
import org.springframework.messaging.simp.config.MessageBrokerRegistry;
import org.springframework.web.socket.config.annotation.EnableWebSocketMessageBroker;
import org.springframework.web.socket.config.annotation.StompEndpointRegistry;
import org.springframework.web.socket.config.annotation.WebSocketMessageBrokerConfigurer;

@Configuration
@EnableWebSocketMessageBroker
public class WebSocketConfig implements WebSocketMessageBrokerConfigurer {

    /**
     * Mesaj sağlayıcıyı yapılandırır.
     * Burada "simple broker" kullanarak "/topic" ve "/queue" gibi destination'ları destekliyoruz.
     * Ayrıca, uygulamaya gönderilecek mesajların prefix'ini "/app" olarak belirtiyoruz.
     */
    @Override
    public void configureMessageBroker(MessageBrokerRegistry registry) {
        // Bu örnekte, basit bir mesaj kuyruğu kullanıyoruz.
        registry.enableSimpleBroker("/topic", "/queue");
        // Tüm istemci istekleri "/app" prefix'iyle başlayacak.
        registry.setApplicationDestinationPrefixes("/app");
    }

    /**
     * STOMP endpoint'ini tanımlar.
     * İstemciler "/ws" endpoint'ine bağlanacak ve SockJS desteği ile fallback mekanizması sağlanacaktır.
     */
    @Override
    public void registerStompEndpoints(StompEndpointRegistry registry) {
        registry.addEndpoint("/ws")
                .setAllowedOriginPatterns("http://localhost:3000")  // Gerekirse belirli origin'leri ayarla.
                .withSockJS();  // SockJS fallback mekanizmasını etkinleştirir.
    }
}
