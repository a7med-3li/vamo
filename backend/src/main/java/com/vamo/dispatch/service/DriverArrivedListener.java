package com.vamo.dispatch.service;

import com.vamo.common.events.DriverArrivedEvent;
import com.vamo.dispatch.dto.DriverArrived;
import com.vamo.ride.entity.Ride;
import com.vamo.ride.service.RideService;
import lombok.RequiredArgsConstructor;
import org.springframework.context.event.EventListener;
import org.springframework.stereotype.Service;

@Service
@RequiredArgsConstructor
public class DriverArrivedListener {
	
	private final ConnectionManager connectionManager;
	private final RideService rideService;
	
	@EventListener
	public void onDriverArrive(DriverArrivedEvent driverArrivedEvent) {
		Ride ride = rideService.getRideById(driverArrivedEvent.rideId());
		DriverArrived driverArrived = new DriverArrived(
				driverArrivedEvent.driverPhone(),
				driverArrivedEvent.vehicleNumber(),
				driverArrivedEvent.pickUpLocation()
		);
		connectionManager.pushDriverArrivedToPassenger(ride.getPassengerId(), driverArrived);
	}
	
}
