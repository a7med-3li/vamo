package com.vamo.common.annotation;


import com.vamo.auth.security.JwtAuthentication;
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
public class DriverIdArgumentResolver implements HandlerMethodArgumentResolver {
	
	@Override
	public boolean supportsParameter(MethodParameter parameter) {
		return parameter.hasParameterAnnotation(CurrentDriverId.class)
				&& parameter.getParameterType().equals(UUID.class);
	}
	
	@Override
	public Object resolveArgument(MethodParameter parameter,
			ModelAndViewContainer mavContainer,
			NativeWebRequest webRequest,
			WebDataBinderFactory binderFactory) {
		
		Authentication authentication = SecurityContextHolder.getContext().getAuthentication();
		
		if (authentication == null || !authentication.isAuthenticated()) {
			throw new AccessDeniedException("User is not authenticated.");
		}
		
		if (authentication instanceof JwtAuthentication jwtAuth) {
			UUID driverId = jwtAuth.getDriverId();
			
			if (driverId == null) {
				throw new AccessDeniedException("User does not have an active driver profile.");
			}
			System.out.println("Resolved driverId from security context: " + driverId);
			return driverId;
		}
		
		throw new AccessDeniedException("Invalid authentication type in security context.");
	}
}
