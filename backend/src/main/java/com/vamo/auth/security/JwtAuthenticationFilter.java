package com.vamo.auth.security;

import jakarta.servlet.FilterChain;
import jakarta.servlet.ServletException;
import jakarta.servlet.http.HttpServletRequest;
import jakarta.servlet.http.HttpServletResponse;
import org.springframework.security.core.authority.SimpleGrantedAuthority;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.security.oauth2.jwt.Jwt;
import org.springframework.security.oauth2.jwt.JwtDecoder;
import org.springframework.security.web.authentication.WebAuthenticationDetailsSource;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;
import org.springframework.context.annotation.Lazy;
import java.io.IOException;
import java.util.Arrays;
import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {
    
    private final JwtDecoder jwtDecoder;
    
    public JwtAuthenticationFilter(@Lazy JwtDecoder jwtDecoder) {
        this.jwtDecoder = jwtDecoder;
    }
    
    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain) throws ServletException, IOException {
        String authHeader = request.getHeader("Authorization");
        
        if (authHeader == null || !authHeader.startsWith("Bearer ")) {
            filterChain.doFilter(request, response);
            return;
        }
        
        try {
            String token = authHeader.substring(7);
            Jwt jwt = jwtDecoder.decode(token);
            
            // Extract claims
            String userId = jwt.getSubject();
            String rolesClaim = jwt.getClaimAsString("roles");
            
            // Extract passenger ID
            String passengerIdStr = jwt.getClaimAsString("passengerId");
            UUID passengerId = (passengerIdStr != null && !passengerIdStr.isEmpty())
                    ? UUID.fromString(passengerIdStr)
                    : null;
            System.out.println("Extracted passengerId from JWT: " + passengerId);
            
            String driverIdStr = jwt.getClaimAsString("driverId");
            UUID driverId = (driverIdStr != null && !driverIdStr.isEmpty())
                    ? UUID.fromString(driverIdStr)
                    : null;
            System.out.println("Extracted driverId from JWT: " + driverId);
            
            List<SimpleGrantedAuthority> authorities = null;
            if (rolesClaim != null && !rolesClaim.isEmpty()) {
                authorities = Arrays.stream(rolesClaim.split(" "))
                        .map(role -> {
                            if (!role.startsWith("ROLE_")) {
                                return new SimpleGrantedAuthority("ROLE_" + role);
                            }
                            return new SimpleGrantedAuthority(role);
                        })
                        .collect(Collectors.toList());
            }
            
            // Update this constructor to accept the passengerId
            JwtAuthentication authentication = new JwtAuthentication(userId, authorities, passengerId, driverId);
            
            authentication.setDetails(new WebAuthenticationDetailsSource().buildDetails(request));
            SecurityContextHolder.getContext().setAuthentication(authentication);
            
        } catch (Exception e) {
            SecurityContextHolder.clearContext();
        }
        
        filterChain.doFilter(request, response);
    }
}
