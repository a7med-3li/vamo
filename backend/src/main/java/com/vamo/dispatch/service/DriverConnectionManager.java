package com.vamo.dispatch.service;

import java.io.IOException;
import java.util.Map;
import java.util.concurrent.ConcurrentHashMap;
import com.vamo.dispatch.dto.DispatchedRide;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Service;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@Service
public class DriverConnectionManager {
	
	public final Map<String, SseEmitter> activeEmitters = new ConcurrentHashMap<>();
	
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
			} catch (IOException e) {
				emitter.completeWithError(e);
				activeEmitters.remove(driverId);
			}
		}
	}
}
