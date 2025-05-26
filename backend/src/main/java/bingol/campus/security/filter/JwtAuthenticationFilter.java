package bingol.campus.security.filter;

import bingol.campus.security.entity.Role;
import bingol.campus.security.entity.User;
import bingol.campus.security.service.JwtService;
import io.jsonwebtoken.Claims;
import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import java.io.IOException;
import java.util.List;
import java.util.Set;
import java.util.stream.Collectors;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    @Autowired
    private JwtService jwtService;

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        if (request.getServletPath().contains("/auth")) {
            filterChain.doFilter(request, response);
            return;
        }

        String authHeader = request.getHeader("Authorization");
        if (authHeader != null && authHeader.startsWith("Bearer ")) {
            String token = authHeader.substring(7);
            try {
                if (jwtService.validateAccessToken(token)) {
                    Claims claims = jwtService.getAccessTokenClaims(token);
                    String userNumber = claims.getSubject(); // Kullanıcı numarasını alıyoruz
                    List<String> rolesAsString = (List<String>) claims.get("role");
                    Set<Role> roles = rolesAsString.stream()
                            .map(roleStr -> Role.valueOf(roleStr.toUpperCase()))
                            .collect(Collectors.toSet());

                    User userDetails = new User(userNumber, roles);
                    UsernamePasswordAuthenticationToken authenticationToken =
                            new UsernamePasswordAuthenticationToken(userDetails, null, userDetails.getAuthorities());
                    SecurityContextHolder.getContext().setAuthentication(authenticationToken);
                }
            } catch (Exception exception) {
                exception.printStackTrace();
            }
        }
        filterChain.doFilter(request, response);
    }
}


