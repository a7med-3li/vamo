package com.vamo.dispatch.service;

import com.vamo.common.events.RideCompletedEvent;
import com.vamo.dispatch.dto.CompletedRide;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class CompletedRideListener {
	
	private final ConnectionManager connectionManager;
	
	@EventListener
	public void onRideCompleted(RideCompletedEvent completedRide) {
		
		CompletedRide ride = new CompletedRide(
				completedRide.rideId(),
				completedRide.passengerId(),
				completedRide.driverName(),
				completedRide.driverPhone(),
				completedRide.vehicleNumber(),
				completedRide.vehicleType(),
				completedRide.pickUpLocation(),
				completedRide.dropOffLocation(),
				completedRide.fare(),
				completedRide.distanceInKm(),
				completedRide.duration()
		);
		connectionManager.pushRideCompletedToPassenger(
				completedRide.passengerId(), ride );
	}
}
