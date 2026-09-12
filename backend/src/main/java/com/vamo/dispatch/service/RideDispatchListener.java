package com.vamo.dispatch.service;

import com.vamo.common.events.RideRequestedEvent;
import com.vamo.dispatch.dto.DispatchedRide;
import lombok.RequiredArgsConstructor;
import lombok.extern.slf4j.Slf4j;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;

@Slf4j
@Service
@RequiredArgsConstructor
public class RideDispatchListener {
	
	private final DriverConnectionManager driverConnectionManager;
	
	@EventListener
	public void handleRideRequested(RideRequestedEvent event) {
		log.info("Received ride request event for rideId: {}",
				event.ride().getPassengerId());
		DispatchedRide dispatchedRide = new DispatchedRide(
				event.ride().getId().toString(),
				event.ride().getPassengerId().toString(),
				event.ride().getPickUp(),
				event.ride().getDropOff(),
				event.ride().getEstimatedFare(),
				event.ride().getDistanceInKm(),
				event.ride().getDuration(),
				event.ride().getStatus()
		);
		for (String targetDriverId : driverConnectionManager.activeEmitters.keySet()){
			driverConnectionManager
					.pushRideRequestToDriver(targetDriverId, dispatchedRide);
		}
	}
}
