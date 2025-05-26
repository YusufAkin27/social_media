package bingol.campus.security.config;

import bingol.campus.security.entity.Role;
import bingol.campus.security.filter.JwtAuthenticationFilter;
import lombok.AllArgsConstructor;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.security.config.annotation.web.builders.HttpSecurity;
import org.springframework.security.config.annotation.web.configuration.EnableWebSecurity;
import org.springframework.security.config.annotation.web.configurers.AbstractHttpConfigurer;
import org.springframework.security.config.http.SessionCreationPolicy;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.security.web.SecurityFilterChain;
import org.springframework.security.web.authentication.UsernamePasswordAuthenticationFilter;
import org.springframework.web.cors.CorsConfiguration;
import org.springframework.web.cors.UrlBasedCorsConfigurationSource;
import org.springframework.web.cors.CorsConfigurationSource;
import java.util.List;

@Configuration
@EnableWebSecurity
@AllArgsConstructor
public class SecurityConfig {

    private final JwtAuthenticationFilter jwtAuthenticationFilter;

    @Bean
    SecurityFilterChain securityFilterChain(HttpSecurity httpSecurity) throws Exception {

        // Public erişim için yollar
        String[] publicPaths = {
                "/v1/api/auth/login/**",
                "/v1/api/admin/register",
                "/v1/api/token/**",
                "/v1/api/student/sign-up/**",
                "/v1/api/student/forgot-password/**",
                "/v1/api/student/reset-password/**",
                "/v1/api/student/active/**",


        };

        // Sadece admin için yollar
        String[] adminPaths = {
                "/v1/api/admin/**"
        };

        // Öğrenci rolleri için yollar
        String[] studentPaths = {
                "/v1/api/student/**"
        };

        return httpSecurity
                .cors(cors -> cors.configurationSource(corsConfigurationSource())) // CORS yapılandırmasını ekledik
                .csrf(AbstractHttpConfigurer::disable) // CSRF'yi devre dışı bırak
                .sessionManagement(session -> session.sessionCreationPolicy(SessionCreationPolicy.STATELESS)) // Stateless yapı
                .authorizeHttpRequests(authorizeRequests -> authorizeRequests
                        .requestMatchers(publicPaths).permitAll()
                        .requestMatchers("/ws/**").permitAll()  // WebSocket için izin ver
                        .requestMatchers(adminPaths).hasAuthority(Role.ADMIN.getAuthority())
                        .requestMatchers(studentPaths).hasAuthority(Role.STUDENT.getAuthority())
                        .anyRequest().authenticated()
                )
                .addFilterBefore(jwtAuthenticationFilter, UsernamePasswordAuthenticationFilter.class)
                .build();
    }

    @Bean
    PasswordEncoder passwordEncoder() {
        return new BCryptPasswordEncoder();
    }

    @Bean
    CorsConfigurationSource corsConfigurationSource() {
        CorsConfiguration configuration = new CorsConfiguration();
        configuration.setAllowedOrigins(List.of("*"
        ));

        configuration.setAllowedMethods(List.of("GET", "POST", "PUT", "DELETE", "OPTIONS"));
        configuration.setAllowedHeaders(List.of("*"));
        configuration.setAllowCredentials(true);

        UrlBasedCorsConfigurationSource source = new UrlBasedCorsConfigurationSource();
        source.registerCorsConfiguration("/**", configuration);
        return source;
    }

}