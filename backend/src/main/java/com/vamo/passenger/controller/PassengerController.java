package com.vamo.passenger.controller;

import java.util.UUID;
import com.vamo.common.annotation.CurrentPassengerId;
import com.vamo.passenger.dto.PassengerActiveRideDTO;
import com.vamo.passenger.service.PassengerService;
import com.vamo.ride.service.RideService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequiredArgsConstructor
@RequestMapping("/api/v1/passengers")
public class PassengerController {
	
	private final PassengerService passengerService;
	private final RideService rideService;
	
	@GetMapping("/ride/active")
	public ResponseEntity<PassengerActiveRideDTO> getActiveRide(
			@CurrentPassengerId UUID passengerId
	) {
		return ResponseEntity.ok(rideService.getRideByPassengerIdAndStatus(passengerId));
	}
}
