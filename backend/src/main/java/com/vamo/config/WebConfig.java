package com.vamo.config;

import java.util.List;
import com.vamo.common.annotation.DriverIdArgumentResolver;
import com.vamo.common.annotation.PassengerIdArgumentResolver;
import org.springframework.context.annotation.Configuration;
import org.springframework.web.method.support.HandlerMethodArgumentResolver;
import org.springframework.web.servlet.config.annotation.CorsRegistry;
import org.springframework.web.servlet.config.annotation.WebMvcConfigurer;

@Configuration
public class WebConfig implements WebMvcConfigurer {
    
    private final PassengerIdArgumentResolver passengerIdArgumentResolver;
    private final DriverIdArgumentResolver driverIdArgumentResolver;
    
    public WebConfig(PassengerIdArgumentResolver passengerIdArgumentResolver, DriverIdArgumentResolver driverIdArgumentResolver) {
        this.passengerIdArgumentResolver = passengerIdArgumentResolver;
        this.driverIdArgumentResolver = driverIdArgumentResolver;
    }
    
    @Override
    public void addArgumentResolvers(List<HandlerMethodArgumentResolver> resolvers) {
        resolvers.add(passengerIdArgumentResolver);
        resolvers.add(driverIdArgumentResolver);
    }
    
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/**")
                .allowedOrigins("http://localhost:5173", "http://localhost:5173/")
                .allowedMethods("GET", "POST", "PUT", "DELETE", "OPTIONS")
                .allowedHeaders("*")
                .allowCredentials(true);
    }
}
