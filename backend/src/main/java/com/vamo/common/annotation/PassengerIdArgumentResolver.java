package com.vamo.common.annotation;

import com.vamo.auth.security.JwtAuthentication;
import org.checkerframework.checker.nullness.qual.NonNull;
import org.springframework.core.MethodParameter;
import org.springframework.security.access.AccessDeniedException;
import org.springframework.security.core.Authentication;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.web.bind.support.WebDataBinderFactory;
import org.springframework.web.context.request.NativeWebRequest;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.method.support.ModelAndViewContainer;
import org.springframework.stereotype.Component;

import java.util.UUID;

@Component
public class PassengerIdArgumentResolver implements HandlerMethodArgumentResolver {
	
	@Override
	public boolean supportsParameter(MethodParameter parameter) {
		return parameter.hasParameterAnnotation(CurrentPassengerId.class)
				&& parameter.getParameterType().equals(UUID.class);
	}
	
	@Override
	public Object resolveArgument(@NonNull MethodParameter parameter,
			ModelAndViewContainer mavContainer,
			@NonNull NativeWebRequest webRequest,
			WebDataBinderFactory binderFactory) {
		
		Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
		
		if (authentication == null || !authentication.isAuthenticated()) {
			throw new AccessDeniedException("User is not authenticated.");
		}
		
		// Check if the authentication is your custom JwtAuthentication
		if (authentication instanceof JwtAuthentication jwtAuth) {
			UUID passengerId = jwtAuth.getPassengerId();
			
			if (passengerId == null) {
				throw new AccessDeniedException("User does not have an active passenger profile.");
			}
			System.out.println("Resolved passengerId from security context: " + passengerId);
			return passengerId;
		}
		
		throw new AccessDeniedException("Invalid authentication type in security context.");
	}
}
