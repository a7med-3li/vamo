package com.vamo.ride.service;

import com.vamo.addressing.entity.Address;
import com.vamo.addressing.service.interfaces.UpdatingAddressCache;
import com.vamo.common.entity.Location;
import com.vamo.common.enums.VehicleType;
import com.vamo.pricing.service.FareCalculationService;
import com.vamo.ride.dto.HereDiscoverResponse;
import com.vamo.ride.dto.HereRouteResponse;
import com.vamo.ride.dto.RideRequestDto;
import com.vamo.ride.dto.RoutingResponse;
import com.vamo.ride.service.interfaces.RoutingService;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.beans.factory.annotation.Qualifier;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Primary;
import org.springframework.http.HttpStatusCode;
import org.springframework.stereotype.Service;
import org.springframework.web.reactive.function.client.WebClient;

import java.math.BigDecimal;
import java.time.Duration;
import java.util.ArrayList;
import java.util.List;
import java.util.Optional;

@Service
@RequiredArgsConstructor
@Qualifier("HereTechnologies")
@Primary
@Slf4j
public class HERERoutingServiceImpl implements RoutingService {

    // TODO find a better way for the api integration and consume the response
    
    private final FareCalculationService fareCalculationService;
    
    @Qualifier("routingClient")
    private final WebClient routeClient;

    @Qualifier("searchClient")
    private final WebClient searchClient;


    @Value("${here.api.key}")
    private String HERE_API_KEY;
    
    public HereRouteResponse calculateRouteInfo(Location from, Location to, String transportMode) {
        String origin = from.getLatitude() + "," + from.getLongitude();
        String destination = to.getLatitude() + "," + to.getLongitude();

        HereRouteResponse response = routeClient.get()
                .uri(uriBuilder -> uriBuilder
                        .queryParam("origin", origin)
                        .queryParam("destination", destination)
                        .queryParam("transportMode", transportMode)
                        .queryParam("return", "summary")
                        .queryParam("apiKey", HERE_API_KEY)
                        .build())
                .retrieve()
                .onStatus(HttpStatusCode::isError, clientResponse ->
                        clientResponse.bodyToMono(String.class)
                                .map(body -> new RuntimeException("HERE API error: " + body))
                )
                .bodyToMono(HereRouteResponse.class)
                .block(); // block because we are in MVC app

        return response;
    }

    @Override
    public List<Address> search(String location) {
        String at = "29.0667,31.0833";
        HereDiscoverResponse response = searchClient.get()
                .uri(uriBuilder -> uriBuilder
                        .queryParam("q", location)
                        .queryParam("at", at)
                        .queryParam("limit", 7)
                        .queryParam("apiKey", HERE_API_KEY)
                        .build())
                .retrieve()
                .bodyToMono(HereDiscoverResponse.class)
                .block();
	    
	    assert response != null;
        assert response.items() != null;
	    List<Address> addresses = response.items().stream()
                .map(this::mapToAddress)
                .toList();

        log.info(response.toString());
        
        return addresses;
    }
    
    @Override
    public List<RoutingResponse> getRideOptions(RideRequestDto rideRequestDto) {
        Location from = rideRequestDto.pickUp();
        Location to = rideRequestDto.dropOff();
        List<RoutingResponse> routingResponses = new ArrayList<>();
        for (int i = 0; i < VehicleType.values().length; i++) {
            HereRouteResponse routeResponse = calculateRouteInfo(from, to, VehicleType.values()[i].name().toLowerCase());
            BigDecimal price = fareCalculationService.calculateFare("CAR",routeResponse.getTotalDistanceMeters()/1000.0, routeResponse.getTotalDurationSeconds()/60.0 );
            routingResponses.add(mapToRoutingResponse(routeResponse, VehicleType.values()[i].name().toLowerCase(), price));
        }
        
        if (routingResponses.isEmpty()) {
            throw new RuntimeException("Failed to retrieve route information from HERE API.");
        }

        return routingResponses;
    }

    private Address mapToAddress(HereDiscoverResponse.Item item) {
        return Address.builder()
                .title(item.title())
                .latitude(item.position().lat())
                .longitude(item.position().lng())
                .build();
    }
    
    private RoutingResponse mapToRoutingResponse(HereRouteResponse response, String transportMode, BigDecimal price) {
        if (response == null
                || response.routes() == null
                || response.routes().isEmpty()) {
            return new RoutingResponse("", 0L, 0L, VehicleType.CAR, price);
        }

        HereRouteResponse.Route route = response.routes().getFirst();
        HereRouteResponse.Section section = route.sections().getFirst();
        HereRouteResponse.Summary summary = section.summary();

        return new RoutingResponse(
                section.polyline(),
                (long) summary.duration(),
                (long) summary.length(),
                VehicleType.valueOf(transportMode.toUpperCase()),
                price
        );
    }
}
