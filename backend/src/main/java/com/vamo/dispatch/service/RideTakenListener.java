package com.vamo.dispatch.service;

import com.vamo.common.events.RideTakenEvent;
import com.vamo.dispatch.dto.TakenRide;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class RideTakenListener {
	
	private final DriverConnectionManager driverConnectionManager;
	
	@EventListener
	public void handleRideRequested(RideTakenEvent event) {
		
		TakenRide takenRide = new TakenRide(
				event.rideId()
		);
		for (String targetDriverId : driverConnectionManager.activeEmitters.keySet()){
			driverConnectionManager
					.pushTakenRideToDriver(targetDriverId, takenRide);
		}
	}
}
