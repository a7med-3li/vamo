package com.vamo.dispatch.service;

import com.vamo.common.events.RideAcceptedEvent;
import com.vamo.dispatch.dto.AcceptedRide;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class RideAcceptedListener {
	
	private final ConnectionManager connectionManager;
	
	@EventListener
	public void onRideAccepted(RideAcceptedEvent rideAcceptedEvent) {
		AcceptedRide acceptedRide = new AcceptedRide(
			rideAcceptedEvent.rideId(),
			rideAcceptedEvent.driverName(),
			rideAcceptedEvent.driverPhone(),
			rideAcceptedEvent.vehicleNumber(),
			rideAcceptedEvent.passengerId(),
			rideAcceptedEvent.vehicleType(),
			rideAcceptedEvent.pickUpLocation(),
			rideAcceptedEvent.dropOffLocation(),
			rideAcceptedEvent.estimatedFare(),
			rideAcceptedEvent.distanceInKm(),
			rideAcceptedEvent.duration(),
			rideAcceptedEvent.status()
		);
		
		connectionManager.pushRideAcceptedToPassenger(
				rideAcceptedEvent.passengerId(), acceptedRide );
	}
}
