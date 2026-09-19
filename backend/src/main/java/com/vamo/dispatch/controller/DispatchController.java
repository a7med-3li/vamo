package com.vamo.dispatch.controller;

import java.util.UUID;
import com.vamo.common.annotation.CurrentDriverId;
import com.vamo.common.annotation.CurrentPassengerId;
import com.vamo.dispatch.service.ConnectionManager;
import lombok.RequiredArgsConstructor;
import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;
import org.springframework.web.servlet.mvc.method.annotation.SseEmitter;

@RestController
@RequestMapping("/api/v1/dispatch")
@RequiredArgsConstructor
public class DispatchController {
	
	private final ConnectionManager connectionManager;
	
	@GetMapping(value = "/drivers/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
	public SseEmitter streamDriverEvents(@CurrentDriverId UUID driverId) {
		return connectionManager.createConnection(String.valueOf(driverId));
	}
	
	@GetMapping(value = "/passengers/stream", produces = MediaType.TEXT_EVENT_STREAM_VALUE)
	public SseEmitter streamPassengerEvents(@CurrentPassengerId UUID passengerId) {
		return connectionManager.createPassengerConnection(String.valueOf(passengerId));
	}
}
