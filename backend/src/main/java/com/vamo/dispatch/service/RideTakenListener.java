package com.vamo.dispatch.service;

import com.vamo.common.events.RideTakenEvent;
import com.vamo.dispatch.dto.NotAvailableRide;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class RideTakenListener {
	
	private final ConnectionManager connectionManager;
	
	@EventListener
	public void handleRideNotAvailable(RideTakenEvent event) {
		
		NotAvailableRide takenRide = new NotAvailableRide(
				event.rideId()
		);
		for (String targetDriverId : connectionManager.activeEmitters.keySet()){
			connectionManager
					.pushRideNotAvailableToDriver(targetDriverId, takenRide);
		}
	}
}
