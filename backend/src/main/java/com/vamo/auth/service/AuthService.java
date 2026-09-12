package com.vamo.auth.service;

import com.vamo.auth.security.SecurityUser;
import com.vamo.common.dto.DriverRegisterRequest;
import com.vamo.common.dto.PassengerRegisterRequest;
import com.vamo.driver.repository.DriverProfileRepository;
import com.vamo.passenger.repository.PassengerProfileRepository;
import com.vamo.user.service.UserService;
import lombok.RequiredArgsConstructor;
import org.springframework.security.authentication.AuthenticationManager;
import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.GrantedAuthority;
import org.springframework.security.core.userdetails.UserDetailsService;
import org.springframework.security.oauth2.jose.jws.MacAlgorithm;
import org.springframework.security.oauth2.jwt.JwsHeader;
import org.springframework.security.oauth2.jwt.JwtClaimsSet;
import org.springframework.security.oauth2.jwt.JwtEncoder;
import org.springframework.security.oauth2.jwt.JwtEncoderParameters;
import org.springframework.stereotype.Service;
import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.stream.Collectors;


@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserService userService;
    private final AuthenticationManager authenticationManager;
    private final UserDetailsService userDetailsService;
    private final JwtEncoder jwtEncoder;
    private final PassengerProfileRepository passengerProfileRepository;
    private final DriverProfileRepository driverProfileRepository;
    
    public SecurityUser authenticate(String email, String password) {
        authenticationManager.authenticate(new UsernamePasswordAuthenticationToken(email, password));
        return (SecurityUser) userDetailsService.loadUserByUsername(email);
    }
    
    public String generateToken(SecurityUser securityUser) {
        Instant now = Instant.now();
        
        String scope = securityUser.getAuthorities().stream()
                .map(GrantedAuthority::getAuthority)
                .collect(Collectors.joining(" "));
        
        JwtClaimsSet.Builder claimsBuilder = JwtClaimsSet.builder()
                .issuer("auth-service")
                .issuedAt(now)
                .expiresAt(now.plus(15, ChronoUnit.MINUTES))
                .subject(securityUser.user().getId().toString())
                .claim("roles", scope);
        
        if (scope.contains("PASSENGER") || scope.equals("BOTH")) {
	        
	        passengerProfileRepository
			        .findByUserId(securityUser.user().getId())
			        .ifPresent(passengerProfile
                            -> claimsBuilder.claim("passengerId",
                            passengerProfile.getId().toString()));
	        
        }
        
        if (scope.contains("DRIVER")    || scope.equals("BOTH")) {
            
            driverProfileRepository
                    .findByUserId(securityUser.user().getId())
                    .ifPresent(driverProfile
                            -> claimsBuilder.claim("driverId",
                            driverProfile.getId().toString()));
            
        }
        
        JwtClaimsSet claims = claimsBuilder.build();
        
        JwsHeader header = JwsHeader.with(MacAlgorithm.HS256).build();
        return jwtEncoder.encode(JwtEncoderParameters.from(header, claims)).getTokenValue();
    }
    
    public void registerPassenger(PassengerRegisterRequest request) {
        userService.registerPassenger(request);
    }
    
    public void registerDriver(DriverRegisterRequest request) {
        userService.registerDriver(request);
    }
    
}
