package com.vamo.dispatch.service;

import java.io.IOException;
import java.util.Map;
import java.util.UUID;
import java.util.concurrent.ConcurrentHashMap;
import com.vamo.common.events.DriverArrivedEvent;
import com.vamo.dispatch.dto.AcceptedRide;
import com.vamo.dispatch.dto.DispatchedRide;
import com.vamo.dispatch.dto.DriverArrived;
import com.vamo.dispatch.dto.NotAvailableRide;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@Service
public class ConnectionManager {
	
	public final Map<String, SseEmitter> activeEmitters = new ConcurrentHashMap<>();
	
	public final Map<String, SseEmitter> activePassengersEmitters = new ConcurrentHashMap<>();
	
	public SseEmitter createConnection(String driverId) {
		SseEmitter emitter = new SseEmitter(900000L);
		
		activeEmitters.put(driverId, emitter);
		
		emitter.onCompletion(() -> activeEmitters.remove(driverId));
		emitter.onTimeout(() -> {
			emitter.complete();
			activeEmitters.remove(driverId);
		});
		emitter.onError((e) -> activeEmitters.remove(driverId));
		
		return emitter;
	}
	
	public void pushRideRequestToDriver(String driverId, DispatchedRide ride) {
		SseEmitter emitter = activeEmitters.get(driverId);
		
		if (emitter != null) {
			try {
				emitter.send(SseEmitter.event()
						.name("ride_request")
						.data(ride, MediaType.APPLICATION_JSON));
			}
			catch (IOException e) {
				emitter.completeWithError(e);
				activeEmitters.remove(driverId);
			}
		}
	}
	
	public void pushRideNotAvailableToDriver(String driverId, NotAvailableRide ride) {
		SseEmitter emitter = activeEmitters.get(driverId);
		
		if (emitter != null) {
			try {
				emitter.send(SseEmitter.event()
						.name("ride_not_available")
						.data(ride, MediaType.APPLICATION_JSON));
			}
			catch (IOException e) {
				emitter.completeWithError(e);
				activeEmitters.remove(driverId);
			}
		}
	}
	
	public void pushCancelledRideToDriver(UUID driverId, UUID rideId) {
		SseEmitter emitter = activeEmitters.get(driverId.toString());
		
		if (emitter != null) {
			try {
				emitter.send(SseEmitter.event()
						.name("ride_cancelled")
						.data(rideId, MediaType.APPLICATION_JSON));
			}
			catch (IOException e) {
				emitter.completeWithError(e);
				activeEmitters.remove(driverId.toString());
			}
		}
	}
	
	public SseEmitter createPassengerConnection(String passengerId) {
		SseEmitter emitter = new SseEmitter(900000L);
		
		activePassengersEmitters.put(passengerId, emitter);
		
		emitter.onCompletion(() -> activePassengersEmitters.remove(passengerId));
		emitter.onTimeout(() -> {
			emitter.complete();
			activePassengersEmitters.remove(passengerId);
		});
		emitter.onError((e) -> activePassengersEmitters.remove(passengerId));
		
		return emitter;
	}
	
	public void pushRideAcceptedToPassenger(UUID passengerId, AcceptedRide ride) {
		SseEmitter emitter = activePassengersEmitters.get(passengerId.toString());
		if (emitter != null) {
			try {
				emitter.send(SseEmitter.event()
						.name("ride_accepted")
						.data(ride, MediaType.APPLICATION_JSON));
			}
			catch (IOException e) {
				emitter.completeWithError(e);
				activePassengersEmitters.remove(passengerId.toString());
			}
		}
	}
	
	public void pushDriverArrivedToPassenger(UUID passengerId, DriverArrived driverArrived) {
		SseEmitter emitter = activePassengersEmitters.get(passengerId.toString());
		if (emitter != null) {
			try {
				emitter.send(SseEmitter.event()
						.name("driver_arrived")
						.data(driverArrived, MediaType.APPLICATION_JSON));
			}
			catch (IOException e) {
				emitter.completeWithError(e);
				activePassengersEmitters.remove(passengerId.toString());
			}
		}
	}
}
