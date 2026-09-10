package com.vamo.ride.controller;

import com.vamo.addressing.entity.Address;
import com.vamo.common.annotation.CurrentPassengerId;
import com.vamo.common.dto.ApiResponse;
import com.vamo.ride.dto.*;
import com.vamo.ride.service.RideService;
import com.vamo.ride.service.interfaces.RoutingService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.annotation.AuthenticationPrincipal;
import org.springframework.web.bind.annotation.*;
import java.util.List;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v3/ride")
public class RideController {

    private final RoutingService routingService;
    private final RideService rideService;

    @PreAuthorize("hasAnyRole('DRIVER', 'BOTH')")
    @PostMapping("/{id}/complete")
    public ResponseEntity<ApiResponse> completeRide(
            @AuthenticationPrincipal String userId,
            @PathVariable UUID id) {
        rideService.completeRide(id, UUID.fromString(userId));
        return ResponseEntity.ok(new ApiResponse(true, "Ride completed"));
    }

    @PreAuthorize("isAuthenticated()")
    @PostMapping("/{id}/cancel")
    public ResponseEntity<ApiResponse> cancelRide(
            @AuthenticationPrincipal String userId,
            @PathVariable UUID id) {
        rideService.cancelRide(id, UUID.fromString(userId));
        return ResponseEntity.ok(new ApiResponse(true, "Ride cancelled"));
    }

    @PreAuthorize("hasAnyRole('PASSENGER', 'BOTH')")
    @GetMapping("/history")
    public ResponseEntity<List<RideHistoryItem>> getPassengerHistory(
            @AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(rideService.getPassengerHistory(UUID.fromString(userId)));
    }

    @PreAuthorize("hasAnyRole('DRIVER', 'BOTH')")
    @GetMapping("/driver/history")
    public ResponseEntity<List<RideHistoryItem>> getDriverHistory(
            @AuthenticationPrincipal String userId) {
        return ResponseEntity.ok(rideService.getDriverHistory(UUID.fromString(userId)));
    }

    @PreAuthorize("hasAnyRole('PASSENGER', 'DRIVER', 'BOTH')")
    @GetMapping("/search")
    public List<Address> search(@RequestParam String location) {
        return routingService.search(location);
    }
    
    @PreAuthorize("hasAnyRole('PASSENGER', 'DRIVER', 'BOTH')")
    @GetMapping("/request")
    public List<RoutingResponse> request(@RequestBody RideRequestDto rideRequestDto) {
        return routingService.getRideOptions(rideRequestDto);
    }
    @PostMapping("/request/publish")
    public ResponseEntity<Void> publishRideRequest(@CurrentPassengerId UUID passengerId, @RequestBody RideRequestDto rideRequestDto) {
        rideService.publishRideRequest(passengerId, rideRequestDto);
        return ResponseEntity.ok().build();
    }
}
