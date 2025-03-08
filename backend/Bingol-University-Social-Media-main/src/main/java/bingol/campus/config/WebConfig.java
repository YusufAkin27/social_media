package bingol.campus.config;

import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.EnableWebMvc;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
@EnableWebMvc
public class WebConfig implements WebMvcConfigurer {

    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**") // Tüm API isteklerine izin ver
                .allowedOrigins(
                        "http://localhost:3000",
                        "http://10.0.2.2:64135",  // Android Emulator (Dart VM Service Portu)
                        "http://10.0.2.2:9101",   // Flutter DevTools için
                        "http://10.0.2.2:54109",  // Flutter Web Portu
                        "http://localhost:54109", // Flutter Web Localhost
                        "http://127.0.0.1:64135", // Dart VM Service Localhost
                        "http://127.0.0.1:9101"   // Flutter DevTools Localhost
                )
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true);
    }
}
